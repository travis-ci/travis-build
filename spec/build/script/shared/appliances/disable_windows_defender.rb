shared_examples_for 'disables Windows Defender' do
  context 'on non-Windows' do
    it { should_not include_sexp [:raw, 'powershell -Command Set-MpPreference -DisableArchiveScanning \\$true'] }
  end

  context 'on Windows' do
    before :each do
      data[:config][:os] = 'windows'
    end

    it 'disables Windows Defender' do
      should include_sexp [:cmd, 'powershell -Command Set-MpPreference -DisableArchiveScanning \\$true', echo: true]
      should include_sexp [:cmd, 'powershell -Command Set-MpPreference -DisableRealtimeMonitoring \\$true', echo: true]
      should include_sexp [:cmd, 'powershell -Command Set-MpPreference -DisableBehaviorMonitoring \\$true', echo: true]
    end
  end
end
