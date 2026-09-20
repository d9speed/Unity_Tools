[CmdletBinding()]
param(
    [string]$package_repo_path = (Join-Path (Split-Path -Parent $PSScriptRoot) '..\unity_editor_tools'),
    [string]$artifacts_path,
    [string]$output_path = (Join-Path (Split-Path -Parent $PSScriptRoot) 'index.json')
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($artifacts_path)) {
    $artifacts_path = Join-Path $package_repo_path 'artifacts\release_0_1_0'
}
# Explicitly select public packages; never discover private repositories or credentials.
$public_package_ids = @(
    'io.github.d9speed.editor_core', 'io.github.d9speed.scene_tools',
    'io.github.d9speed.humanoid_alias_copy', 'io.github.d9speed.package_exporter',
    'io.github.d9speed.rename_tool', 'io.github.d9speed.animation_tools',
    'io.github.d9speed.skinned_mesh_tools', 'io.github.d9speed.prefab_color_variants',
    'io.github.d9speed.screen_texture_capture', 'io.github.d9speed.cloth_fitting_tools'
)
$external_vpm_dependencies = @('com.vrchat.avatars')
$listing_url = 'https://d9speed.github.io/Unity_Tools/index.json'
$listing_id = 'io.github.d9speed.unity_tools'
$listing = [ordered]@{
    name = 'D9speed Unity Tools'
    id = $listing_id
    url = $listing_url
    author = 'd9speed <d09pseed@gmail.com>'
    packages = [ordered]@{}
}
if (Test-Path -LiteralPath $output_path) {
    $listing = Get-Content -LiteralPath $output_path -Raw | ConvertFrom-Json -AsHashtable
    if ($listing.id -cne $listing_id -or $listing.url -cne $listing_url) { throw 'Unexpected repository identity' }
    foreach ($id in $listing.packages.Keys) {
        if ($id -notin $public_package_ids) { throw "Package is not approved for this listing: $id" }
    }
}
$artifact_report = @(Get-Content -LiteralPath (Join-Path $artifacts_path 'package_artifacts.json') -Raw | ConvertFrom-Json)
Add-Type -AssemblyName System.IO.Compression.FileSystem
$seen = @{}
foreach ($artifact in $artifact_report) {
    $id = $artifact.package
    if ($id -notin $public_package_ids -or $seen.ContainsKey($id)) { throw "Unexpected or duplicate artifact: $id" }
    $seen[$id] = $true
    $source_manifest = Get-Content -LiteralPath (Join-Path $package_repo_path "packages\$id\package.json") -Raw | ConvertFrom-Json
    $version = $source_manifest.version
    $zip_name = "$id-$version.zip"
    $zip_path = Join-Path $artifacts_path $zip_name
    $hash = (Get-FileHash -LiteralPath $zip_path -Algorithm SHA256).Hash.ToLowerInvariant()
    $record = @($artifact_report | Where-Object { $_.package -ceq $id -and $_.version -ceq $version })
    if ($record.Count -ne 1 -or $record[0].sha256 -cne $hash -or $record[0].zip -cne $zip_name) { throw "Artifact report mismatch: $id" }
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zip_path)
    try {
        $entry = $archive.GetEntry('package.json')
        if ($null -eq $entry) { throw "ZIP manifest must be at root: $zip_name" }
        if ($null -eq $archive.GetEntry('LICENSE.md')) { throw "License is missing: $zip_name" }
        $reader = [System.IO.StreamReader]::new($entry.Open())
        try { $manifest = $reader.ReadToEnd() | ConvertFrom-Json -AsHashtable } finally { $reader.Dispose() }
    } finally { $archive.Dispose() }
    if ($manifest.name -cne $id -or $manifest.version -cne $version) { throw "ZIP package identity mismatch: $id" }
    if ($manifest.license -cne 'MIT' -or $manifest.author.email -cne 'd09pseed@gmail.com') { throw "Unexpected publication details: $id" }
    $package_short_name = $id.Substring('io.github.d9speed.'.Length)
    $expected_url = "https://github.com/d9speed/unity_editor_tools/releases/download/${package_short_name}_v$version/$zip_name"
    if ($manifest.url -cne $expected_url -or $source_manifest.url -cne $expected_url) { throw "Unexpected download URL: $id" }
    if ($manifest.Contains('vpmDependencies')) {
        foreach ($dependency in $manifest.vpmDependencies.Keys) {
            if ($dependency -notin $public_package_ids -and $dependency -notin $external_vpm_dependencies) { throw "Dependency is not approved: $dependency" }
        }
    }
    $manifest.zipSHA256 = $hash
    if (-not $listing.packages.Contains($id)) { $listing.packages[$id] = [ordered]@{ versions = [ordered]@{} } }
    $versions = $listing.packages[$id].versions
    if ($versions.Contains($version) -and ($versions[$version].zipSHA256 -cne $hash -or $versions[$version].url -cne $manifest.url)) {
        throw "Do not replace an existing version. Increment package version: $id $version"
    }
    $versions[$version] = $manifest
}
$listing | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $output_path -Encoding utf8NoBOM
Write-Output "Listing ready: $output_path"
