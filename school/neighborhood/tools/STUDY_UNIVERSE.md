# Shared study content → Roblox

The existing active school project uses a server-only QuestionBank with numeric
answer indices. This adapter converts the private app’s content-only JSON export
to that same shape and preserves the legacy deterministic question IDs.

Run the exporter with reviewed content, never private learner answers:

python import_study_universe.py reviewed-pack.json --out QuestionBank.lua --receipt receipt.json

Do not embed private-site credentials in Roblox. Export through an authorized
parent/agent context, review the receipt, and publish the bank through the game’s
existing release gates. No live game publication or cross-platform learner-progress
sync is claimed by this adapter.
