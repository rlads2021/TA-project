# Use custom fonts in shiny
# https://stackoverflow.com/questions/51812219/using-custom-fonts-on-shinyapps-io
dir.create('~/.fonts')
system('tar xf NotoSansMonoCJKtc.tar.xz')
file.copy("NotoSansMonoCJKtc.otf", "~/.fonts")
system('fc-cache -f ~/.fonts')
