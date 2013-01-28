function travis_start($a) {
    $global:TRAVIS_STAGE=$a
    echo "[travis:$a:start]" <%= ">> #{logs[:state]}" if logs[:state] %>
}

function travis_finish($a,$b) {
  echo "[travis:$a:finish:result=$b]" <%= ">> #{logs[:state]}" if logs[:state] %>
  Start-Sleep -Seconds 1
}

function travis_assert() {
  $result=$LastExitCode
  if ( $result -ne 0 ) {
    echo -e "\nThe last command ailed and exited with $result during $(global:TRAVIS_STAGE).\n\nYour build has been stopped." <%= ">> #{logs[:log]}" if logs[:log] %>
    travis_terminate 2
  }
}

function travis_terminate($a) {
  travis_finish build $a
  exit $a
}

IF (Test-Path <%= BUILD_DIR %>){
    Remove-Item <%= BUILD_DIR %>
}
New-Item -type directory     <%= BUILD_DIR %> | out-null
cd                           <%= BUILD_DIR %>

[System.IO.Directory]::SetCurrentDirectory($PWD)

trap { travis_finish build 1 }

travis_start build