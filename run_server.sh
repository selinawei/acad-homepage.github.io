#!/usr/bin/env bash
# Local preview: http://localhost:4000
#
# github-pages pins Liquid 4.0.3, which calls Object#tainted? / #untaint — methods
# Ruby removed in 3.2. Since the github-pages gem forces Jekyll safe mode (so a
# _plugins/ shim would be ignored), we inject a no-op shim via RUBYOPT instead.
# None of this affects the deployed GitHub Pages build.
set -euo pipefail

cd "$(dirname "$0")"

# Prefer a modern Ruby from Homebrew over macOS system Ruby 2.6.
if [ -d /opt/homebrew/opt/ruby/bin ]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

# Bundler fails to install gems under a path with non-ASCII characters
# (e.g. 个人资质/), so keep gems in an ASCII-only directory.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export BUNDLE_PATH="$HOME/.homepage-gems"
bundle check >/dev/null 2>&1 || bundle install

SHIM="$(mktemp -t jekyll_taint_shim).rb"
trap 'rm -f "$SHIM"' EXIT
cat > "$SHIM" <<'RUBY'
class Object
  def tainted?
    false
  end

  def untaint
    self
  end
end
RUBY

RUBYOPT="-r$SHIM" exec bundle exec jekyll serve --livereload --force_polling --host 127.0.0.1 --port 4000
