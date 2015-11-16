
function pssh_refresh {
  pssh -h /etc/pssh/all hostname | grep SUCCESS | awk '{print $4}' > /etc/pssh/avail
}


function pssh_avail {
  [ -f /etc/pssh/avail ] || pssh_refresh
  pssh -h /etc/pssh/avail $*
}

