use std::{
    collections::{BTreeMap, HashMap},
    fs,
    fs::File,
    io::{BufWriter, Write},
    path::Path,
};

use anyhow::{anyhow, bail, Context, Result};
use rbx_dom_weak::WeakDom;
use rbx_types::{Ref, Variant};
use serde::{Deserialize, Serialize};
use serde_json::json;
use sha2::{Digest, Sha256};
use ustr::ustr;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Manifest {
    baseline_sha256: String,
    patches: Vec<Patch>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Patch {
    id: String,
    target_path: String,
    expected_source_sha256: String,
    #[allow(dead_code)]
    reason: Option<String>,
    replacements: Vec<Replacement>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct Replacement {
    old: String,
    new: String,
    expected_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct AppliedPatch {
    id: String,
    target_path: String,
    class: String,
    before_source_sha256: String,
    after_source_sha256: String,
    replacements: Vec<ReplacementReceipt>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct ReplacementReceipt {
    expected_count: usize,
    old_sha256: String,
    new_sha256: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct PatchReceipt {
    schema_version: u32,
    baseline_sha256: String,
    applied_patches: Vec<AppliedPatch>,
}

#[derive(Debug, PartialEq, Eq)]
struct Snapshot {
    hierarchy: BTreeMap<(String, String), usize>,
    scripts: BTreeMap<(String, String), Vec<String>>,
    total_instances: usize,
}

fn sha256_bytes(bytes: &[u8]) -> String {
    format!("{:x}", Sha256::digest(bytes))
}

fn sha256_text(text: &str) -> String {
    sha256_bytes(text.as_bytes())
}

fn read_dom(path: &Path) -> Result<(Vec<u8>, WeakDom)> {
    let bytes = fs::read(path).with_context(|| format!("read {}", path.display()))?;
    let dom = rbx_binary::from_reader(bytes.as_slice())
        .with_context(|| format!("parse Roblox binary {}", path.display()))?;
    Ok((bytes, dom))
}

fn snapshot(dom: &WeakDom) -> Snapshot {
    let mut hierarchy = BTreeMap::new();
    let mut scripts: BTreeMap<(String, String), Vec<String>> = BTreeMap::new();
    let mut total_instances = 0usize;

    for inst in dom.descendants() {
        total_instances += 1;
        let path = dom.full_path_of(inst.referent(), "/");
        let class = inst.class.to_string();
        *hierarchy.entry((path.clone(), class.clone())).or_insert(0) += 1;

        if class == "Script" || class == "LocalScript" || class == "ModuleScript" {
            let source_hash = match inst.properties.get(&ustr("Source")) {
                Some(Variant::String(source)) => sha256_text(source),
                Some(other) => format!("NON_STRING:{:?}", other.ty()),
                None => "MISSING_SOURCE".to_string(),
            };
            scripts.entry((path, class)).or_default().push(source_hash);
        }
    }

    for hashes in scripts.values_mut() {
        hashes.sort();
    }

    Snapshot {
        hierarchy,
        scripts,
        total_instances,
    }
}

fn compare_semantics(baseline: &WeakDom, working: &WeakDom, receipt: &PatchReceipt) -> Result<()> {
    let before = snapshot(baseline);
    let after = snapshot(working);

    if before.total_instances != after.total_instances {
        bail!(
            "instance-count drift: {} != {}",
            before.total_instances,
            after.total_instances
        );
    }

    if before.hierarchy != after.hierarchy {
        let mut missing = Vec::new();
        let mut extra = Vec::new();

        for (key, count) in &before.hierarchy {
            let after_count = after.hierarchy.get(key).copied().unwrap_or(0);
            if *count > after_count {
                missing.push((key.clone(), *count - after_count));
            }
        }
        for (key, count) in &after.hierarchy {
            let before_count = before.hierarchy.get(key).copied().unwrap_or(0);
            if *count > before_count {
                extra.push((key.clone(), *count - before_count));
            }
        }

        bail!(
            "exact hierarchy/name/class drift: missing={:?} extra={:?}",
            &missing[..missing.len().min(20)],
            &extra[..extra.len().min(20)]
        );
    }

    if before.scripts.keys().collect::<Vec<_>>() != after.scripts.keys().collect::<Vec<_>>() {
        bail!("script path/class inventory drift");
    }

    let mut approved: HashMap<(String, String), &AppliedPatch> = HashMap::new();
    for patch in &receipt.applied_patches {
        approved.insert((patch.target_path.clone(), patch.class.clone()), patch);
    }

    for (key, before_hashes) in &before.scripts {
        let after_hashes = after
            .scripts
            .get(key)
            .ok_or_else(|| anyhow!("missing working script {:?}", key))?;

        if let Some(patch) = approved.get(key) {
            if before_hashes.len() != 1 || after_hashes.len() != 1 {
                bail!("approved patched script path is not unique: {:?}", key);
            }
            if before_hashes[0] != patch.before_source_sha256 {
                bail!(
                    "approved patch baseline hash mismatch for {:?}: {} != {}",
                    key,
                    before_hashes[0],
                    patch.before_source_sha256
                );
            }
            if after_hashes[0] != patch.after_source_sha256 {
                bail!(
                    "approved patch working hash mismatch for {:?}: {} != {}",
                    key,
                    after_hashes[0],
                    patch.after_source_sha256
                );
            }
        } else if before_hashes != after_hashes {
            bail!("unapproved script-source drift at {:?}", key);
        }
    }

    println!("RHS_BINARY_STRUCTURAL_PARITY_OK");
    println!("INSTANCES {}", before.total_instances);
    println!("SCRIPT_PATHS {}", before.scripts.len());
    println!("INTENTIONAL_SCRIPT_CHANGES {}", receipt.applied_patches.len());
    Ok(())
}

fn patch(input: &Path, manifest_path: &Path, output: &Path, receipt_path: &Path) -> Result<()> {
    let manifest: Manifest = serde_json::from_slice(
        &fs::read(manifest_path).with_context(|| format!("read {}", manifest_path.display()))?,
    )
    .context("parse patch manifest")?;

    let (input_bytes, mut dom) = read_dom(input)?;
    let input_sha = sha256_bytes(&input_bytes);
    if input_sha != manifest.baseline_sha256 {
        bail!(
            "baseline SHA-256 mismatch inside binary patcher: {} != {}",
            input_sha,
            manifest.baseline_sha256
        );
    }

    let baseline_dom = rbx_binary::from_reader(input_bytes.as_slice())
        .context("parse immutable baseline for semantic comparison")?;

    let mut path_index: HashMap<String, Vec<Ref>> = HashMap::new();
    for inst in dom.descendants() {
        path_index
            .entry(dom.full_path_of(inst.referent(), "/"))
            .or_default()
            .push(inst.referent());
    }

    let mut applied = Vec::new();

    for patch in &manifest.patches {
        let refs = path_index
            .get(&patch.target_path)
            .ok_or_else(|| anyhow!("patch {} target not found: {}", patch.id, patch.target_path))?;

        if refs.len() != 1 {
            bail!(
                "patch {} target path is not unique: {} matched {} instances",
                patch.id,
                patch.target_path,
                refs.len()
            );
        }

        let referent = refs[0];
        let inst = dom
            .get_by_ref_mut(referent)
            .ok_or_else(|| anyhow!("patch {} target referent vanished", patch.id))?;

        let class = inst.class.to_string();
        if class != "Script" && class != "LocalScript" && class != "ModuleScript" {
            bail!(
                "patch {} target is not a script class: {} ({})",
                patch.id,
                patch.target_path,
                class
            );
        }

        let source_variant = inst
            .properties
            .get_mut(&ustr("Source"))
            .ok_or_else(|| anyhow!("patch {} target has no Source property", patch.id))?;

        let source = match source_variant {
            Variant::String(value) => value,
            other => bail!(
                "patch {} Source is {:?}, expected String",
                patch.id,
                other.ty()
            ),
        };

        let before_source_sha256 = sha256_text(source);
        if before_source_sha256 != patch.expected_source_sha256 {
            bail!(
                "patch {} source hash mismatch: {} != {}",
                patch.id,
                before_source_sha256,
                patch.expected_source_sha256
            );
        }

        let mut updated = source.clone();
        let mut replacement_receipts = Vec::new();

        for replacement in &patch.replacements {
            let actual_count = updated.matches(&replacement.old).count();
            if actual_count != replacement.expected_count {
                bail!(
                    "patch {} replacement count mismatch at {}: {} != {}",
                    patch.id,
                    patch.target_path,
                    actual_count,
                    replacement.expected_count
                );
            }

            updated = updated.replace(&replacement.old, &replacement.new);
            replacement_receipts.push(ReplacementReceipt {
                expected_count: replacement.expected_count,
                old_sha256: sha256_text(&replacement.old),
                new_sha256: sha256_text(&replacement.new),
            });
        }

        let after_source_sha256 = sha256_text(&updated);
        *source = updated;

        applied.push(AppliedPatch {
            id: patch.id.clone(),
            target_path: patch.target_path.clone(),
            class,
            before_source_sha256,
            after_source_sha256,
            replacements: replacement_receipts,
        });
    }

    let receipt = PatchReceipt {
        schema_version: 1,
        baseline_sha256: manifest.baseline_sha256.clone(),
        applied_patches: applied,
    };

    let root_ids = dom.root().children().to_vec();
    let file = File::create(output).with_context(|| format!("create {}", output.display()))?;
    let mut writer = BufWriter::new(file);
    rbx_binary::to_writer(&mut writer, &dom, &root_ids)
        .with_context(|| format!("write Roblox binary {}", output.display()))?;
    writer.flush()?;
    drop(writer);

    let (_, reparsed) = read_dom(output)?;
    compare_semantics(&baseline_dom, &reparsed, &receipt)?;

    fs::write(receipt_path, serde_json::to_vec_pretty(&receipt)?)
        .with_context(|| format!("write {}", receipt_path.display()))?;

    println!("RHS_BINARY_PATCHES_APPLIED {}", receipt.applied_patches.len());
    println!("WORKING_BINARY_SHA256 {}", sha256_bytes(&fs::read(output)?));
    Ok(())
}

fn parity(baseline_path: &Path, working_path: &Path, receipt_path: &Path) -> Result<()> {
    let (_, baseline) = read_dom(baseline_path)?;
    let (_, working) = read_dom(working_path)?;
    let receipt: PatchReceipt = serde_json::from_slice(
        &fs::read(receipt_path).with_context(|| format!("read {}", receipt_path.display()))?,
    )
    .context("parse build patch receipt")?;
    compare_semantics(&baseline, &working, &receipt)
}

fn check(path: &Path) -> Result<()> {
    let (bytes, dom) = read_dom(path)?;
    println!("RHS_BINARY_PARSE_OK");
    println!("SHA256 {}", sha256_bytes(&bytes));
    println!("INSTANCES {}", dom.descendants().count());
    Ok(())
}

fn usage() -> ! {
    eprintln!(
        "usage:\n  rhs-binary-patcher patch <input.rbxl> <manifest.json> <output.rbxl> <receipt.json>\n  rhs-binary-patcher parity <baseline.rbxl> <working.rbxl> <receipt.json>\n  rhs-binary-patcher check <file.rbxl>"
    );
    std::process::exit(2);
}

fn main() -> Result<()> {
    let args: Vec<String> = std::env::args().collect();
    match args.as_slice() {
        [_, cmd, input, manifest, output, receipt] if cmd == "patch" => patch(
            Path::new(input),
            Path::new(manifest),
            Path::new(output),
            Path::new(receipt),
        ),
        [_, cmd, baseline, working, receipt] if cmd == "parity" => parity(
            Path::new(baseline),
            Path::new(working),
            Path::new(receipt),
        ),
        [_, cmd, path] if cmd == "check" => check(Path::new(path)),
        _ => usage(),
    }
}
