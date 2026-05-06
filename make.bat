@ECHO OFF
pushd %~dp0

REM Command file for Sphinx documentation

set SOURCEDIR=.
set BUILDDIR=_build

REM -- Try sphinx-build, then py/python -m sphinx as fallback --
set SPHINXCMD=
for %%C in (sphinx-build.exe sphinx-build) do (
    where %%C >NUL 2>NUL && set SPHINXCMD=%%C && goto :found
)
for %%P in (py python3 python) do (
    %%P -c "import sphinx" >NUL 2>NUL && set SPHINXCMD=%%P -m sphinx && goto :found
)

echo.
echo.The 'sphinx-build' command was not found. Make sure you have Sphinx
echo.installed:  pip install sphinx
echo.
exit /b 1

:found
if "%~1"=="" (
    %SPHINXCMD% -M help "%SOURCEDIR%" "%BUILDDIR%" %SPHINXOPTS% %O%
) else (
    %SPHINXCMD% -M %1 "%SOURCEDIR%" "%BUILDDIR%" %SPHINXOPTS% %O%
)

popd
