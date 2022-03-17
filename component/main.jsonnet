local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.floodgate;

local commonLabels = {
  'app.kubernetes.io/name': 'floodgate',
  'app.kubernetes.io/instance': inv.parameters._instance,
  'app.kubernetes.io/version': params.images.floodgate.tag,
  'app.kubernetes.io/managed-by': 'commodore',
  'app.kubernetes.io/component': 'floodgate',
};


local serviceAccount = kube.ServiceAccount('floodgate') {
  metadata+: {
    labels+: commonLabels,
  },
};

local deployment = kube.Deployment('floodgate') {
  metadata+: {
    labels+: commonLabels,
  },
  spec+: {
    template+: {
      spec+: {
        containers_:: {
          floodgate: kube.Container('floodgate') {
            image: '%(registry)s/%(repository)s:%(tag)s' % params.images.floodgate,
            env_:: {
              FG_IMAGE_DAY: params.imageDay,
            },
            ports_:: {
              http: {
                containerPort: 8080,
              },
            },
            [if params.resources != null then 'resources']:
              std.prune(params.resources),
          },
        },
        serviceAccountName: serviceAccount.metadata.name,
      },
    },
  },
};

local service = kube.Service('floodgate') {
  metadata+: {
    labels+: commonLabels,
  },
  target_pod:: deployment.spec.template,
};

local ingress = kube.Ingress(params.ingress.hostname) {
  metadata+: {
    annotations+: std.prune(params.ingress.annotations),
    labels+: commonLabels,
  },
  spec+: {
    rules: [
      {
        host: params.ingress.hostname,
        http: {
          paths: [
            {
              backend: service.name_port,
            },
          ],
        },
      },
    ],
    tls: [
      {
        hosts: [ params.ingress.hostname ],
        secretName: '%s-tls' % params.ingress.hostname,
      },
    ],
  },
};

{
  '00_namespace': kube.Namespace(params.namespace) {
    metadata+: {
      labels+: commonLabels + std.prune(params.namespaceLabels),
    },
  },
  '10_serviceaccount': serviceAccount,
  '10_deployment': deployment,
  '20_service': service,
  '20_ingress': ingress,
}
