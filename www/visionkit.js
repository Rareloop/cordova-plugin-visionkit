/*global cordova, module*/

module.exports = {
    scan: function (successCallback, errorCallback) {
        cordova.exec(successCallback, errorCallback, "VisionKit", "scan", [name]);
    }
};
