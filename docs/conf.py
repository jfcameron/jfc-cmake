# © Joseph Cameron - MIT License

import os
import pathlib

project = 'jfc-cmake'
author = 'Joseph Cameron'
copyright = 'Joseph Cameron, MIT License'

extensions = ['sphinxcontrib.moderncmakedomain']

primary_domain = 'cmake'
highlight_language = 'cmake'

exclude_patterns = ['_build']

_docs = pathlib.Path(__file__).parent
_root = _docs.parent
_generated = _docs / 'generated'


def _write_stubs(aSection, aSources):
    directory = _generated / aSection
    directory.mkdir(parents=True, exist_ok=True)

    wanted = {}
    for source in aSources:
        stub = directory / f'{source.stem}.rst'
        wanted[stub] = f'.. cmake-module:: {pathlib.Path(os.path.relpath(source, directory)).as_posix()}\n'

    for stale in set(directory.glob('*.rst')) - set(wanted):
        stale.unlink()

    for stub, content in wanted.items():
        if not stub.exists() or stub.read_text() != content:
            stub.write_text(content)


_write_stubs('module', sorted(_root.glob('modules/*/*.cmake')))
_write_stubs('toolchain', sorted(_root.glob('toolchains/*.cmake')))
