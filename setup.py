from distutils.core import setup, Extension

module1 = Extension('vimkeylogparser', sources = ['vimlogs.c'])

setup (name = 'VimKeylogParser',
        version = '1.0',
        description = 'Parsing vim keylogs produced by `vim -w`',
        ext_modules = [module1])
