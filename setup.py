from setuptools import setup, Extension

module1 = Extension('vimkeylog', sources = ['vimkeylog.c'])

setup (name = 'vimkeylog',
        version = '1.0',
        description = 'Parsing vim keylogs produced by `vim -w`',
        ext_modules = [module1])
