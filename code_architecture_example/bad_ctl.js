/*globals angular */
'use strict';
angular.module('app').controller('mainCtl', function ($scope, ajaxService) {

  function processArrFromServer() {
    ajaxService('GET', 'server_url/arrays/3').then(function processRespose(response) {
      var arr = [];
      var acc = 0;
      //assume here we extract data from response into arr...
      $scope.arr = arr;
      $scope.arr.forEach(function (num) {
        acc += num;
      });
      $scope.acc = acc;
    });
  }

  $scope.init = function () {
    processArrFromServer();
  };
});