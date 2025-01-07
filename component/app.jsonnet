local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.floodgate;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('floodgate', params.namespace);

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/floodgate' % appPath]: app,
}
