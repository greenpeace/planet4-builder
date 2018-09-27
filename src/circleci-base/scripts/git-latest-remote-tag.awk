#!/usr/bin/awk -f
BEGIN {
  if (ARGC != 2) {
    print "git-latest-remote-tag.awk https://github.com/greenpeace/planet4-docker"
    exit
  }
  FS = "[ /^]+"
  while ("git ls-remote " ARGV[1] "| sort -Vk2" | getline) {
    if ($2~/tags/ && $3~/^v[0-9]+/)
      tag = $3
  }
  printf "%s\n", tag
}
