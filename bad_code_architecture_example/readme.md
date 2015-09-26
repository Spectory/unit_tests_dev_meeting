
Bad code architecture example:
-------------------------------

say we want a ng-controller that gets an array of numbers form server, then store it & its accumulative value on scope

this will do the trick
```javaScript
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
    ajaxService('GET', 'server_url/arrays/3').then(processArrFromServer);
  };
```

init function does 3 things:
  - get data from the server
  - process the response into $scope.arr
  - accumulate the arr into $scope.acc

In order to test this ctl, we must test init. we must mock the http response.

We can do better

-----------------------
Lets do it again, this time however, we follow the *'each function does one thing'* rule.

```javaScript
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
```

init function still does the same 3 things:
  - get data from the server
  - process the response into $scope.arr
  - accumulate the arr into $scope.acc

We did 2 things here:
 - break the logical flow into steps, each function responsible for a single step. calling init triggers the flow.
 - Only init is needed at our html view. we want to avoid placing other functions on the $scope. So we place the 'helper functions' on the controller object (self). This allows us to get access to the functions while running unit tests.

This architecture gives us much more flexabilty. It allows us to choose what to test, and what not to pretty easily.
  - in order to test accumulateArr, we just need to set $scope.arr to some value.
  - in order to test processRespose, we can pass it a general response json.
  - in order to test init, we must mock the http request.

Notice that we can can get a pretty nice code coverage **without testing init at all**.