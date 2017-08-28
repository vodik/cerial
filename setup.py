import os
from setuptools import setup, find_packages
from setuptools.extension import Extension
import sys


try:
    from Cython.Distutils import build_ext
    USE_CYTHON = True
except ImportError:
    USE_CYTHON = False


cmdclass = {}
long_description=open('README.rst', encoding='utf-8').read()


if USE_CYTHON:
    ext_modules = [
        Extension("cerial.struct", ["cerial/struct.pyx"],
                  language="c++",
                  extra_compile_args=["-std=c++11"])
    ]
    cmdclass['build_ext'] = build_ext
else:
    ext_modules = [
        Extension("cerial.struct", ["cerial/struct.cpp"],
                  language="c++",
                  extra_compile_args=["-std=c++11"])
    ]


setup(
    name='cerial',
    version='0.0.1',
    author='Simon Gomizelj',
    author_email='simon@vodik.xyz',
    packages=find_packages(),
    license="Apache 2",
    url='https://github.com/vodik/cerial',
    description='Python3 serializer with memoryview support',
    long_description=long_description,
    cmdclass = cmdclass,
    ext_modules=ext_modules,
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
    ],
)
