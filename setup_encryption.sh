#!/bin/bash

# Sets up transparent encryption/decrytion of files in git repository.
# please export the password in ${TETAPAC_PASSPHRASE} environment variable

function global_setup {
  mkdir -p ${HOME}/.gitencrypt > /dev/null
  pushd ${HOME}/.gitencrypt > /dev/null

  touch clean_filter_gpg smudge_filter_gpg diff_filter_gpg
  chmod 755 *

  echo "Generating ${HOME}/.gitencrypt/clean_filter_gpg"

  cat > clean_filter_gpg <<-'EOF'
	#!/bin/bash

	gpg --yes --batch --passphrase ${TETAPAC_PASSPHRASE} --symmetric  --cipher-algo AES256
EOF

  echo "Generating ${HOME}/.gitencrypt/smudge_filter_gpg"

  cat > smudge_filter_gpg <<-'EOF'
	#!/bin/bash

	# If decryption fails, use cat instead.
	# Error messages are redirected to /dev/null.
	gpg --yes --batch --passphrase ${TETAPAC_PASSPHRASE} --decrypt 2> /dev/null || cat
EOF

  echo "Generating ${HOME}/.gitencrypt/diff_filter_gpg"

  cat > diff_filter_gpg <<-'EOF'
	#!/bin/bash

	# Error messages are redirect to /dev/null.
	gpg --yes --batch --passphrase ${TETAPAC_PASSPHRASE} --decrypt "$1" 2> /dev/null || cat "$1"
EOF
  popd > /dev/null
}

function repo_setup {
  touch .gitattributes

  cat >> .gitattributes <<-'EOF'
	.gitattributes !filter !diff
EOF

  git config --local --type path filter.gpg.smudge ${HOME}/.gitencrypt/smudge_filter_gpg
  git config --local --type path filter.gpg.clean ${HOME}/.gitencrypt/clean_filter_gpg
  git config --local --type bool filter.gpg.required true
  git config --local --type path diff.gpg.textconv ${HOME}/.gitencrypt/diff_filter_gpg
}

if [[ -e ${HOME}/.gitencrypt ]]; then
    echo "${HOME}/.gitencrypt already exists. Refusing to clobber existing global setup."
else
    global_setup
fi

# Make this idempotent
echo "Setting up this repository for transparent encryption."
repo_setup
