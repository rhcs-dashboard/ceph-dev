local grafana = import '../../../../grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local prometheus = grafana.prometheus;
local annotation = grafana.annotation;
local graphPanelSchema(title, nullPointMode, stack, formatY1, formatY2, labelY1, labelY2, min, fill, datasource) =
graphPanel.new(title=title,nullPointMode=nullPointMode,stack=stack,formatY1=formatY1,formatY2=formatY2,labelY1=labelY1,labelY2=labelY2,min=min,fill=fill,datasource=datasource);
local addTargetSchema(expr, intervalFactor, format, legendFormat) =
prometheus.target(expr=expr,intervalFactor=intervalFactor,format=format,legendFormat=legendFormat);
local addTemplateSchema(name, datasource, query, refresh, hide, includeAll, sort) =
template.new(name=name,datasource=datasource,query=query,refresh=refresh,hide=hide,includeAll=includeAll, sort=sort);
 
dashboard.new(
  title='RGW Sync Overview',
  uid='rgw-sync-overview',
  time_from='now-1h',
  refresh='15s',
  schemaVersion=16,
  tags=["overview"],
  timezone='',
  timepicker={refresh_intervals:['5s','10s','15s','30s','1m','5m','15m','30m','1h','2h','1d'],time_options:['5m','15m','1h','6h','12h','24h','2d','7d','30d']}
)

.addAnnotation(
  grafana.annotation.datasource(
    builtIn= 1,
    datasource= '-- Grafana --',
    enable= true,
    hide= true,
    iconColor= 'rgba(0, 211, 255, 1)',
    name= 'Annotations & Alerts',
    type= 'dashboard'
  )
)

.addRequired(type= 'grafana',id= 'grafana',name= 'Grafana',version= '5.0.0')

.addRequired(type= 'panel',id= 'graph',name= 'Graph',version= '5.0.0')

.addTemplate(
  addTemplateSchema('rgw_servers', '$datasource', 'prometehus', 1, 2, true, 1)
)

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    'default',
    label='Data Source'
  )
)

.addPanels([
  graphPanelSchema('Replication (throughput) from Source Zone', 'null as zero', true, 'Bps', 'short', null, null, 0, 1, '$datasource')
  .addTargets([addTargetSchema('sum by (source_zone) (rate(ceph_data_sync_from_zone_fetch_bytes_sum[30s]))', 1, 'time_series', '{{source_zone}}')])
             + {gridPos: {h: 7, w: 8, x: 0, y: 0}},

  graphPanelSchema('Replication (objects) from Source Zone', 'null as zero', true, 'short', 'short', 'Objects/s', null, 0, 1, '$datasource')
  .addTargets([addTargetSchema('sum by (source_zone) (rate(ceph_data_sync_from_zone_fetch_bytes_count[30s]))', 1, 'time_series', '{{source_zone}}')])
             + {gridPos: {h: 7, w: 7.4, x: 8.3, y: 0}},

  graphPanelSchema('Polling Request Latency from Source Zone', 'null as zero', true, 'ms', 'short', null, null, 0, 1, '$datasource')
  .addTargets([addTargetSchema('sum by (source_zone) (rate(ceph_data_sync_from_zone_poll_latency_sum[30s]) * 1000)', 1, 'time_series', '{{source_zone}}')])
             + {gridPos: {h: 7, w: 8, x: 16, y: 0}},

  graphPanelSchema('Unsuccessful Object Replications from Source Zone', 'null as zero', true, 'short', 'short', 'Count/s', null, 0, 1, '$datasource')
  .addTargets([addTargetSchema('sum by (source_zone) (rate(ceph_data_sync_from_zone_fetch_errors[30s]))', 1, 'time_series', '{{source_zone}}')])
             + {gridPos: {h: 7, w: 8, x: 0, y: 7}},           
])
