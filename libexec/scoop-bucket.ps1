# Usage: scoop bucket add|list|known|rm [<args>]
# Summary: Manage Scoop buckets
# Help: Add, list or remove buckets.
#
# Buckets are repositories of apps available to install. Scoop comes with
# a default bucket, but you can also add buckets that you or others have
# published.
#
# To add a bucket:
#     scoop bucket add <name> [<repo>]
#
# e.g.:
#     scoop bucket add extras https://github.com/ScoopInstaller/Extras.git
#
# Since the 'extras' bucket is known to Scoop, this can be shortened to:
#     scoop bucket add extras
#
# To list all known buckets, use:
#     scoop bucket known
param($cmd, $name, $repo)

if (get_config NO_JUNCTION) {
    . "$PSScriptRoot\..\lib\versions.ps1"
}

if (get_config USE_SQLITE_CACHE) {
    . "$PSScriptRoot\..\lib\manifest.ps1"
    . "$PSScriptRoot\..\lib\database.ps1"
}

$usage_add = 'usage: scoop bucket add <name> [<repo>]'
$usage_rm = 'usage: scoop bucket rm <name>'

switch ($cmd) {
    'add' {
        if (!$name) {
            '<name> missing'
            $usage_add
            exit 1
        }
        if (!$repo) {
            $repo = known_bucket_repo $name
            if (!$repo) {
                "Unknown bucket '$name'. Try specifying <repo>."
                $usage_add
                exit 1
            }
        }
        $status = add_bucket $name $repo
        exit $status
    }
    'rm' {
        if (!$name) {
            '<name> missing'
            $usage_rm
            exit 1
        }
        $status = rm_bucket $name
        exit $status
    }
    'list' {
        $buckets = list_buckets
        if (!$buckets.Length) {
            warn "No bucket found. Please run 'scoop bucket add main' to add the default 'main' bucket."
            exit 2
        } else {
            Get-LocalBucket | ForEach-Object {
                $bucketLoc = Find-BucketDirectory $_ -Root
                if (Test-GitAvailable -and (Test-Path "$bucketLoc\.git")) {
                    Write-Host "'$_' bucket:"
                    Invoke-Git -Path $bucketLoc -ArgumentList @('log', 'HEAD', '-1', '--oneline')
                    Write-Host ''
                }
            }
            $buckets
            exit 0
        }
    }
    'known' {
        known_buckets
        exit 0
    }
    default {
        "scoop bucket: cmd '$cmd' not supported"
        my_usage
        exit 1
    }
}
