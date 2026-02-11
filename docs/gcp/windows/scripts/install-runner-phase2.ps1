# install-runner-phase2.ps1 -- Post-reboot provisioner for Windows runner images.
#
# This script runs AFTER the VM has been rebooted with the Containers feature
# enabled. It completes the Docker installation and performs cleanup.
#
# Runs after install-runner.ps1 + windows-restart provisioner.

$ErrorActionPreference = "Stop"

$dockerPath = "$env:ProgramFiles\docker"

# ---------------------------------------------------------------------------
# Register dockerd as a Windows service
# ---------------------------------------------------------------------------
Write-Host ">>> Registering dockerd as a Windows service"

# Now that the Containers feature is fully activated post-reboot,
# vmcompute.dll is available and dockerd can register successfully.
& "$dockerPath\dockerd.exe" --register-service

Write-Host "Docker service registered successfully"

# ---------------------------------------------------------------------------
# Cleanup for smallest possible image
# ---------------------------------------------------------------------------
Write-Host ">>> Cleaning up"

# DISM cleanup is optional (controlled by dism_cleanup variable in Packer).
# Saves ~2 GB but adds 20-40 min to build time. Not needed for ephemeral runners.
if ($env:DISM_CLEANUP -eq "true") {
    Write-Host "Running DISM cleanup (this may take 20-40 minutes)..."
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase /Quiet
    Write-Host "DISM cleanup complete"
} else {
    Write-Host "Skipping DISM cleanup (dism_cleanup=false)"
}

# Remove temp files
Write-Host "Removing temp files"
Remove-Item -Recurse -Force "$env:TEMP\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\Windows\Temp\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\Windows\SoftwareDistribution\Download\*" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "C:\Windows\Logs\CBS\*" -ErrorAction SilentlyContinue

Write-Host ">>> Phase 2 complete"
