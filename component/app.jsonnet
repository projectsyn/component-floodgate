local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.floodgate;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('floodgate', params.namespace);

{
  floodgate: app,
}
