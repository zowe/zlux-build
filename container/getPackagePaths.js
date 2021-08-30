/*
#########################################################################################
#                                                                                       #
# This program and the accompanying materials are made available under the terms of the #
# Eclipse Public License v2.0 which accompanies this distribution, and is available at  #
# https://www.eclipse.org/legal/epl-v20.html                                            #
#                                                                                       #
# SPDX-License-Identifier: EPL-2.0                                                      #
#                                                                                       #
# Copyright IBM Corporation 2021                                                        #
#                                                                                       #
#########################################################################################
*/

const { binaryDependencies: zowePackages } = require('./files/manifest.json');
const baseUrl = process.env.ZOWE_REPOSITORY || 'https://zowe.jfrog.io/artifactory';
async  function getPackageUrls() {
    let zluxPrefix = 'org.zowe.zlux';
    let urls = []
    let packages = []
    for (const [key, value] of Object.entries(zowePackages)) {
		let { repository, version, artifact } = value;
		if (key.startsWith(zluxPrefix)) {
			let { repository, version, artifact } = value;
			if (repository == 'libs-snapshot-local'){
				let packageName = key.replace(zluxPrefix + '.', '');
				packages.push(packageName)
				urls.push(`${baseUrl}/${repository}/org/zowe/zlux/${packageName}/${version}/${artifact.replace('.pax', '.tar')}`);
			}else{
				let packageName = key.replace(zluxPrefix + '.', '');
				let versionName = value['version'].replace('~', '');
				let artifactName = value['artifact'].replace('.pax', '.tar')
				let result  = await artifactory(packageName, versionName, artifactName);
				packages.push(packageName)
				urls.push(`${baseUrl}/${result}`);
				
			}
        }
    }
	//console.log(urls);
    return `${packages.toString()};${urls.toString()}`;
}

getPackageUrls().then(res => console.log(res));


function findArtifact(name, version, artifact){
  return new Promise(resolve => {
    const https = require('https')
    const data = `items.find({"repo": "libs-snapshot-local", "path": {"$match": "org/zowe/zlux/${name}/*${version}"}, "name": {"$match": "${artifact}"}})`
	console.log(data)
	const options ={
      hostname: 'zowe.jfrog.io',
      path: '/zowe/api/search/aql',
      method: 'POST',
      headers: {
        'X-JFrog-Art-Api':`${{ secrets.JF_ARTIFACTORY_TOKEN }}`
      }
    }
    var ret = '';
    const req = https.request(options, (res) => {
      //console.log(`statusCode: ${res.statusCode}`)
      res.on('data', (d) => {
        ret += d;
        })
      res.on('error', (err) => {
      })
      res.on('end', () => {
        resolve(JSON.parse(ret));
      })
      });
	  req.write(data)
      req.end();
  })
}

function sortArtifacts(names){
	return names['results'].sort(function(a,b){
		return b.updated.localeCompare(a.updated, undefined, {
			numeric: true,
			sensitivity: 'base'
		});
	});
	
}

async function artifactory(name, version, artifact){
	data = await findArtifact(name, version, artifact);
	sortArtifacts(data)
	let results = data['results'][0]['repo'] + '/' + data['results'][0]['path'] + '/' + data['results'][0]['name']
	return results
}
