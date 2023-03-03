cask 'phpmon-dev' do
  depends_on formula: 'gnu-sed'

  version '5.7.2_1035'
  sha256 '1cb147bd1b1fbd52971d90dff577465b644aee7c878f15ede57f46e8f217067a'

  url 'https://github.com/nicoverbruggen/phpmon/releases/download/v5.7.2/phpmon-dev.zip'
  appcast 'https://github.com/nicoverbruggen/phpmon/releases.atom'
  name 'PHP Monitor DEV'
  homepage 'https://phpmon.app'

  app 'PHP Monitor DEV.app', target: "PHP Monitor DEV.app"
end

