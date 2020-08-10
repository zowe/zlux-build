from distutils.core import setup
import json
import os
import sys
import glob

print('Loading package attributes from pluginDefinition.json')
with open('./plugin/pluginDefinition.json', 'r') as f:
  pluginDef = json.load(f)
  if ('license' in pluginDef):
      license = pluginDef['license']
  else:
      license = "UNKNOWN"

  if ('webContent' in pluginDef):
      if ('descriptionDefault' in pluginDef['webContent']):
          description=pluginDef['webContent']['descriptionDefault']
      else:
          description=""
  else:
      description=""

  if ('homepage' in pluginDef):
    homepage=pluginDef['homepage']
  else:
    homepage=""

  if ('descriptionDefault' in pluginDef):
      description = pluginDef['descriptionDefault']

  buildnumber=os.getenv('ZLUX_BUILD_NUMBER')
      
  if (sys.platform != 'zos'):
    noarch="  noarch: generic"
  else:
    noarch="# zos build"

  setup(name=pluginDef['identifier'],
        version=pluginDef['pluginVersion'],
        description=description,
        license=license,
        homepage=homepage,
        noarch=noarch,
        buildnumber=buildnumber )
  
#    uiVersion=f"- zowe-ui {uiVersion}"
