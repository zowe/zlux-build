const { binaryDependencies: zowePackages } = require('./files/manifest.json');
const baseUrl = process.env.ZOWE_REPOSITORY || 'https://zowe.jfrog.io/artifactory';
function getPackageUrls() {
    let zluxPrefix = 'org.zowe.zlux';
    let urls = []
    let packages = [] 
    for (const [key, value] of Object.entries(zowePackages)) {
        if (key.startsWith(zluxPrefix)) {
            let packageName = key.replace(zluxPrefix + '.', '');
            packages.push(packageName)
            let { repository, version, artifact } = value;
            urls.push(`${baseUrl}/${repository}/org/zowe/zlux/${packageName}/${version}/${artifact.replace('.pax', '.tar')}`);
        }
    }
    //console.log(urls);
    return `${packages.toString()};${urls.toString()}`;
}

console.log(getPackageUrls())



