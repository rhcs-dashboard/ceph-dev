Steps to setup Grafana Dashboard for embedding:-
In a working directory:-
1. `git clone https://github.com/ceph/ceph.git`
2. `git clone https://github.com/rhcs-dashboard/ceph-dev.git`

After build and setting up docker for ceph.
1. To bring node-exporter, prometheus and Grafana services up `docker-compose up prometheus`

Once all the services are up
1. Login to `localhost:3000` (admin/admin)
2. Add prometheus as data source
3. Import json files one by one by clicking `+` on left Dashboard

Now
1. Start ceph container, `docker-compose up ceph`

Plugins required for grafana are :-
1. https://grafana.com/plugins/grafana-piechart-panel
2. https://grafana.com/plugins/vonage-status-panel
