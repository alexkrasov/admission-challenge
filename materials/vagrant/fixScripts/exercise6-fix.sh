#!/bin/bash

#Make sure there are at least 2 arguments given (n-1 for source files and n for destination path)
function check_arguments {
  if [ "$#" -lt 2 ]; then
    echo "Error: At least two arguments are required."
    exit 1
  fi
}

#Make sure all files does actualy exist and accessable
function check_files {
  for file_path in "${@:1:$#-1}"; do
    if ! sudo test -f "$file_path"; then
      echo "Error: File $file_path does not exist."
      exit 1
    fi
  done
}

#Resolve remote server name by assuming either server1 or server2
function resolve_remote_server_name {
  if [ "$(hostname)" == "server1" ]; then
    echo "server2"
  elif [ "$(hostname)" == "server2" ]; then
    echo "server1"
  else
    echo "Error: Unknown server."
    exit 1
  fi
}

#Copy files, break and exit on error
function copy_file_to_remote_server {
  local bytes=$(sudo stat -c %s "$1")
  #echo "$(hostname) -> $remote_server_name: copying $1 with size of $bytes bytes to $dest_path" >&2
  #Use rsync instead of scp to overcome permission issues with existing files
  sudo rsync -av --rsync-path="sudo rsync" "$1" "$USER@$remote_server_name:$dest_path" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Error: Failed to copy $1 to $dest_path on the other server."
    exit 1
  fi
  # Return the size of the copied file
  echo "$bytes"
}

# Check arguments
check_arguments "$@"

# Check files
check_files "${@:1:$#-1}"

# Get remote server name
remote_server_name=$(resolve_remote_server_name)

# Destination path, last parameter
dest_path="${!#}"

# Initialize byte counter
total_bytes=0

# Iterate through all files
for file_path in "${@:1:$#-1}"; do
  file_size=$(copy_file_to_remote_server "$file_path")
  #Test for numeric output and accumulate total bytes if it's valid, otherwise echo it 
  if [[ $file_size =~ ^[0-9]+$ ]]; then
	total_bytes=$((total_bytes + file_size))
  else
	echo $file_size
  fi
done

# Print total bytes
echo "$total_bytes"

exit 0