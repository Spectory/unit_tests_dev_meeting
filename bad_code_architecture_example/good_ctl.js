/*globals angular */
'use strict';

angular.module('app').controller('mainCtl', function ($scope, ajaxService) {
  var self = this;

  self.accumulateArr = function () {
    var acc = 0;
    $scope.arr.forEach(function (num) {
      acc += num;
    });
    return acc;
  };

  self.processRespose = function (response) {
    var arr = [];
    //assume here we extract data from response into arr...
    $scope.arr = arr;
    self.accumulateArr();
  };

  $scope.init = function () {
    ajaxService('GET', 'server_url/arrays/3').then(self.processRespose);
  };
});