# Test if a while ($true) loop will work

function Main-Menu {
    while ($true) {
        Running loop...
        $p = '1'
        switch ($p) {
            '0' {
                return
            }
            '1' {
                return
            }
        }
    }
}



Main-Menu
Write-Host "Return returned the whole function not just in a scope sense"