const Gun = require('gun');
require('gun/lib/path.js');
const fs = require('fs');
const { performance } = require('perf_hooks');

// From https://github.com/gundb/synchronous/blob/master/synchronous.js
(function (env) {
  Gun.chain.sync = function (obj, opt, callback, o) {
    var gun = this;
    if (!Gun.obj.is(obj)) {
      console.log('First param is not an object');
      return gun;
    }
    if (Gun.bi.is(opt)) {
      opt = {
        meta: opt,
      };
    }
    if (Gun.fn.is(opt)) {
      callback = opt;
      opt = null;
    }
    callback = callback || function () {};
    opt = opt || {};
    opt.ctx = opt.ctx || {};
    gun.on(function (change, field) {
      Gun.obj.map(
        change,
        function (val, field) {
          if (!obj) {
            return;
          }
          if (field === '_' || field === '#') {
            if (opt.meta) {
              obj[field] = val;
            }
            return;
          }
          if (Gun.obj.is(val)) {
            var soul = Gun.val.rel.is(val);
            if (opt.ctx[soul + field]) {
              // don't re-subscribe.
              return;
            }
            // unique subscribe!
            opt.ctx[soul + field] = true;
            this.path(field).sync((obj[field] = obj[field] || {}), Gun.obj.copy(opt), callback, o || obj);
            return;
          }
          obj[field] = val;
        },
        this
      );
      callback(o || obj);
    });
    return gun;
  };
})();

(function (env) {
  Gun.chain.currentState = function (obj, opt, callback, o) {
    var gun = this;
    return gun['_'].graph;
  };
})();

const peers = fs
  .readFileSync('nodes.txt')
  .toString()
  .replace(/\r\n/g, '\n')
  .split('\n')
  .filter((peer) => peer != '');
console.log('peers', peers);

const gun = Gun({
  peers: peers.map((peer) => 'http://' + peer + ':8080/gun'),
  uuid: () => 'client',
  radisk: true,
  localStorage: false,
  // TODO: Uncomment
  //   file: 'testdata',
});

// Get Args
const args = process.argv.slice(2);
// node receive.js <mode:collect/aggregate> <intervalBegin:ISODate> <intervalEnd:ISODate>
// node receive.js aggregate 2017-07-31T00:00:00Z 2017-07-31T23:59:59Z
// node --trace_gc receive.js aggregate 2017-07-31T00:00:00Z 2017-07-31T23:59:59Z
// node test.py aggregate 2017-07-31T00:00:00Z 2017-07-31T23:59:59Z

const startDate = new Date(args[1]);
const endDate = new Date(args[2]);
console.log('startDate', startDate);
console.log('endDate', endDate);

// For the distributed database there is no difference between the aggregate and collect mode, as both need the data locally.

// Interval check in ms
interval = 500;

const receivedKeys = new Set();

function getData(key, callback, expectedLength) {
  //   console.log('getData', key);

  gun.get(key).once((data) => {
    // // console.log(data);
    // if (data == undefined || Object.keys(data).length < expectedLength + 1) {
    //   //   if (data != undefined) {
    //   //   console.log(Object.keys(data).length);
    //   //   }
    //   //   getData(key, callback, expectedLength);
    // } else {
    //   clearInterval(timerRef);
    //   gun.get(key).off();
    //   // gundb off doesn't seem to work
    //   if (!receivedKeys.has(key)) {
    //     receivedKeys.add(key);
    //     callback(data);
    //   }
    // }
    // // console.log(data);
  });

  let result = {};
  //   gun.get(key).sync(result);

  let timerRef = setInterval(() => {
    let test = gun.currentState();
    result = test[key];

    // Compare with length + 1 (for internal object)
    // if (data == undefined || Object.keys(data).length < expectedLength + 1) {
    //   if (data != undefined) {
    // console.log(Object.keys(data).length);
    //   }
    //   getData(key, callback, expectedLength);
    // gun.get(key).once((new_data) => {
    //   //   if (new_data != undefined) {
    //   //     console.log(Object.keys(new_data).length);
    //   //   }
    // });
    // DO Nothing as we will receive the data in the .on() callback
    // data = new_data;
    // console.log(data);
    //   });
    // } else {
    //   //   clearTimeout(timerRef);
    //   callback(data);
    // }

    if (result == undefined || Object.keys(result).length < expectedLength) {
      //   console.log('hi');
      //   if (result != undefined) {
      //   console.log(Object.keys(result).length);
      //   }
      //   getData(key, callback, expectedLength);
    } else {
      clearInterval(timerRef);
      gun.get(key).off();
      // gundb off doesn't seem to work
      if (!receivedKeys.has(key)) {
        receivedKeys.add(key);
        callback(result);
      }
    }
  }, interval);
}

timer('sensors');
timer('sensors_datapoints');
timer('sensors_datapoints_data');

sensors = {};
sensor_datapoints = {};
sensor_datapoint_count = {};
retrieved_sensor_data_points = {};
check_loaded_points = {};

console.log(peers.length);
getData(
  'sensors',
  (sensors_data) => {
    timer('sensors');
    // console.log(sensors_data);
    sensors = Object.keys(removeMetaData(sensors_data));
    checkDataPoints();
    sensors.forEach((sensor) => {
      // Get datapoint_count
      getData(
        sensor + '-datapointcount',
        (data) => {
          datapointcount = removeMetaData(data);
          sensor_datapoint_count[sensor] = datapointcount;
          console.log(sensor + ' overall datapointcount:', datapointcount.count);
          getData(
            sensor,
            (data) => {
              sensor_datapoints[sensor] = removeMetaData(data);
              console.log(sensor, Object.keys(data).length);
            },
            datapointcount.count
          );
        },
        1
      );
    });
  },
  peers.length
);

// Check if all data points have been loaded before continuing (the list of datapoints)
let checkDataPoints = () => {
  setTimeout(() => {
    console.log('loaded list of sensor datapoints for sensors:', Object.keys(sensor_datapoints).length);
    if (Object.keys(sensor_datapoints).length >= sensors.length) {
      timer('sensors_datapoints');
      console.log('loaded sensor points');

      sensors.forEach((sensor) => {
        retrieved_sensor_data_points[sensor] = {};
        Object.keys(sensor_datapoints[sensor])
          .filter((datapointId) => {
            // Datapoint format <sensor>-<timestamp>, e.g. sensor-1-2017-07-11T06:54:45
            // To accomodate more than 9 sensor we find the index
            let date = new Date(datapointId.slice(datapointId.indexOf('-', 7) + 1));
            // Retrieve data point if in time interval
            if (date > startDate && date < endDate) {
              return true;
            } else {
              delete sensor_datapoints[sensor][datapointId];
              // Hacky way of removing datapoints that are not needed so we don't have to wait for retrieval
              return false;
            }
          })
          // Load each individual datapoint
          .forEach((key) => {
            getData(
              key,
              (data) => {
                //   retrieved_sensor_data_points[sensor][key] = data;
                //   Save Memory by just forgetting about the data:
                retrieved_sensor_data_points[sensor][key] = true;
                // console.log(key, data);
              },
              1
            );
          });
      });
      checkForRetrievedDataPoints();
    } else {
      checkDataPoints();
    }
  }, 1000);
};

// Check if the points data have been loaded before continuing (the content)
let checkForRetrievedDataPoints = () => {
  setTimeout(() => {
    console.log('retrieved data points');

    sensors.forEach((sensor) => {
      console.log(
        sensor,
        Object.keys(retrieved_sensor_data_points[sensor]).length,
        '/',
        Object.keys(sensor_datapoints[sensor]).length
      );
      if (
        Object.keys(retrieved_sensor_data_points[sensor]).length >=
        Object.keys(sensor_datapoints[sensor]).length - 1
      ) {
        check_loaded_points[sensor] = true;
      }
    });

    console.log(check_loaded_points);
    if (Object.keys(check_loaded_points).length >= sensors.length) {
      timer('sensors_datapoints_data');
      console.log('all data points loaded');
      exit();
    } else {
      checkForRetrievedDataPoints();
    }
  }, 1000);
};

function exit() {
  fs.rmdirSync('./radata', { recursive: true });
  fs.readdirSync('.').map((e) => {
    if (e.endsWith('.tmp')) {
      fs.unlinkSync(e);
    }
  });
  process.exit();
}

function timer(lap) {
  if (lap) console.log(`${lap} in: ${(performance.now() - timer.prev).toFixed(3)}ms`);
  timer.prev = performance.now();
}

const removeMetaData = (o) => {
  // A
  const copy = { ...o };
  //   try {
  //     copy.id = copy._['#'];
  //   } catch (e) {
  //     console.log('no id');
  //   }
  delete copy._;
  return copy;
};
