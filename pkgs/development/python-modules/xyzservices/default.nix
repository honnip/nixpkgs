{
  lib,
  buildPythonPackage,
  fetchPypi,
  mercantile,
  pytestCheckHook,
  requests,
  setuptools,
  setuptools-scm,
}:

buildPythonPackage rec {
  pname = "xyzservices";
  version = "2024.9.0";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-aPuDU8nbuk8f9sDy5eTllrueHbf5T099+8sm4lqmb94=";
  };

  nativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  pytestFlagsArray = [
    # requires network connections
    "-m 'not request'"
  ];

  pythonImportsCheck = [ "xyzservices.providers" ];

  nativeCheckInputs = [
    mercantile
    pytestCheckHook
    requests
  ];

  meta = {
    changelog = "https://github.com/geopandas/xyzservices/releases/tag/${version}";
    description = "Source of XYZ tiles providers";
    homepage = "https://github.com/geopandas/xyzservices";
    license = lib.licenses.bsd3;
    maintainers = lib.teams.geospatial.members;
  };
}
