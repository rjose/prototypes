function get_mocked_data() {
        var result = {}
        result.tracks = ["All", "Track 1", "Track 2"]

        result.staffing_stats = {
                skills: ['Apps', 'Native', 'Web'],
                required: {'Apps': 11, 'Native': 2, 'Web': 2},
                available: {'Apps': 4, 'Native': 3, 'Web': 2},
                net_left: {'Apps': -7, 'Native': 1, 'Web': 0},
                feasible_line: 2
        };

        result.work_items = [
                {rank: 5, triage: 1, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 8, triage: 1, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 15, triage: 1.5, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'},
                {rank: 22, triage: 2, track: 'Track Alpha', name: 'Something to do', estimate: 'Apps: Q, Native: 3S, Web: M'}
        ];

        return result;
}

function WorkCtrl($scope, $http) {
        $scope.default_track = "All";
        $scope.tracks = [$scope.default_track];
        $scope.selected_track = $scope.default_track;
        $scope.triage = 1.5;
        $scope.staffing_stats = {
                skills: [],
                required: {},
                available: {},
                net_left: {},
                feasible_line: 100
        };
        $scope.work_items = [];

        $scope.update = function() {
                console.log("Update: " + $scope.triage + " " + $scope.selected_track);
                var data = get_mocked_data();
                $scope.tracks = data.tracks;
                $scope.staffing_stats = data.staffing_stats;
                $scope.work_items = data.work_items;
//                $http.get('/app/web/work?triage=' + $scope.triage + "&track=" + $scope.selected_track).then(
//                                function(res) {
//                                        console.log("TODO: Handle the query args");
//                                        console.dir(res);
//
//                                        var tmp = [$scope.default_track];
//                                        $scope.tracks = tmp.concat(res.data.tracks);
//                                        $scope.staffing_stats = res.data.staffing_stats;
//                                        $scope.work_items = res.data.work_items;
//                                },
//                                function(res) {
//                                        console.log("Ugh.");
//                                        console.dir(res);
//                                });
        };

        $scope.selectTrack = function(track) {
                angular.forEach($scope.tracks, function(t) {
                        if (t == track) {
                                $scope.selected_track = t;
                                $scope.update();
                        }
                });
        };



        // A helper function to convert a tags hash to a string
        $scope.tags_to_string = function(tags) {
                var keys = [];
                for (var key in tags) {
                        keys.push(key)
                }
                keys.sort()

                var result = "";
                for (var i in keys) {
                        var key = keys[i];
                        if (tags[key]) {
                                result = result + key + ": " + tags[key] + ", "
                        }
                }
                // Get rid of trailing comma
                if (result.length >= 2) {
                        result = result.slice(0, result.length-2);
                }
                return result;
        };

        // Update
        $scope.update();
}

