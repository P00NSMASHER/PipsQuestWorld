# Exact-source semantic image QA (October 9)

The existing nonblank image gate could pass while the real classroom art
was visibly missing. A focused gate now uses only two FIXED generated camera
views: 16-rug-overlook.png and 17-library-cover-fronts.png.

The rug check requires a clearly colored sun disk, warm ray pixels across
at least 11 of 16 radial sectors, and at least eight distinct large pale
cloud components arranged around the center. The book check samples five
known cover locations and demands chromatic, nonblank illustration pixels,
contrast and five distinct face colors. Screens are normalized to 960x540.

Adversarial self-tests use only SYNTHETIC images and must reject a missing
sunburst, missing clouds and one blank cream storybook. Before integration,
the exact 21139ae source-render artifact was privately examined with the
same pixel thresholds: 2121 sun-center pixels, 16 ray sectors, 10 cloud
components, five distinct colored covers. Thresholds were set below those
measured values; they are not calibrated against any user video.

This new pixel gate is part of the source-render CI, not the playable game.
It does not read student photographs, private recordings, Roblox account
screens, or personal identifiers. Source-rendered colors/shapes cannot
certify actual Roblox mobile shaders, SurfaceGui text, FPS or visual approval.
A new owner iPhone walkthrough is needed for native acceptance.

The independent foliage pixels in 07-eye-windows and the new 18th close-up
remain protected by their existing, separate checks.
