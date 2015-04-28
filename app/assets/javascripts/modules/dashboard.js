angular.module('probe-dock.dashboard', [ 'probe-dock.api', 'probe-dock.orgs', 'probe-dock.reports' ])

  .controller('DashboardHeaderCtrl', function(orgs, $scope, $state, $stateParams) {

    orgs.forwardData($scope);
    $scope.orgName = $stateParams.orgName;

    var modal;
    $scope.currentState = $state.current.name;

    $scope.$on('$stateChangeSuccess', function(event, toState) {

      $scope.currentState = toState.name;

      if (toState.name == 'org.dashboard.default.edit') {
        modal = orgs.openForm($scope);

        modal.result.then(function() {
          $state.go('^', {}, { inherit: true });
        }, function(reason) {
          if (reason != 'stateChange') {
            $state.go('^', {}, { inherit: true });
          }
        });
      }
    });
  })

  .controller('DashboardNewTestMetricsCtrl', function(api, $scope, $stateParams) {

    fetchMetrics().then(showMetrics);

    $scope.chart = {
      data: [],
      labels: [],
      options: {
        tooltipTemplate: '<%= value %> new tests on <%= label %>'
      }
    };

    $scope.chartFormatX = function(timestamp) {
      return moment(timestamp).format('ll');
    };

    $scope.chartTooltip = function(key, x, y, e, graph) {
      return y + ' new tests on ' + moment(new Date(x)).format('ll');
    };

    function fetchMetrics() {
      return api({
        method: 'GET',
        url: '/api/metrics/newTests',
        params: {
          organizationName: $stateParams.orgName
        }
      });
    }

    function showMetrics(response) {
      if (!response.data.length) {
        return;
      }

      var series = [];
      $scope.chart.data = [ series ];

      _.each(response.data, function(data) {
        $scope.chart.labels.push(moment(data.date).format('ddd'));
        series.push(data.testsCount);
      });

      console.log($scope.chart);
    }
  })

  .controller('DashboardTagCloudCtrl', function(api, $scope, $stateParams) {

    fetchTags().then(showTags);

    function fetchTags() {
      return api({
        method: 'GET',
        url: '/api/tags',
        params: {
          organizationName: $stateParams.orgName
        }
      });
    }

    function showTags(response) {
      $scope.tags = _.reduce(response.data, function(memo, tag) {

        memo.push({
          text: tag.name,
          weight: tag.testsCount
        });

        return memo;
      }, []);
    }
  })

  .controller('DashboardLatestReportsCtrl', function(api, reportService, $scope, $stateParams) {

    fetchLatestReports().then(showReports);

    function fetchLatestReports() {
      return api({
        method: 'GET',
        url: '/api/reports',
        params: {
          pageSize: 8,
          organizationName: $stateParams.orgName
        }
      });
    }

    function showReports(response) {
      $scope.reports = response.data;
    }
  })

;
