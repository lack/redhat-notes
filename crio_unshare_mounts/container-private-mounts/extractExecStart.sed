#sed -n -e '/^ExecStart=.*\\$/,/[^\\]$/p' -e '/^ExecStart=.*[^\\]$/p'
/^ExecStart=.*\\$/,/[^\\]$/ { s/^ExecStart=//; p }
/^ExecStart=.*[^\\]$/ { s/^ExecStart=//; p }
