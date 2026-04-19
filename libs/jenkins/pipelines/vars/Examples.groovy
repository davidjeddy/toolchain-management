#!groovy

@Library('toolchain-management')

// IAC Shared Module
// Module(Number, Number, String, String)
// Module(ProjectGitLabId, PipelineTimeout, CronSchedule, SlackChannel)
// Module(3319, 'H 4 * * 1-5', 15, 'nl-pros-centaurus-squad-releases')
// Note The CRON schedule is Jenkins enabled timer. Meaning we can do random times within an hour bound. https://www.jenkins.io/doc/book/pipeline/syntax/
SharedModule(
    78465,
    15,
    'H */6 * * 1-5',
    'nl-pros-centaurus-squad-releases'
)

// ContainerImage(Number, Number, String, String)
// ContainerImage(ProjectGitLabId, PipelineTimeout, CronSchedule, SlackChannel)
// ContainerImage(3319, 'H 4 * * 1-5', 15, 'nl-pros-centaurus-squad-releases')
// Note The CRON schedule is Jenkins enabled timer. Meaning we can do random times within an hour bound. https://www.jenkins.io/doc/book/pipeline/syntax/
ContainerImage(
    81236,
    15,
    'worldline-gc-cicd-build-prod',
    '891377244928.dkr.ecr.eu-west-1.amazonaws.com/prd/toolbox/jenkins-agents-wl-gc-ansible-2-9/m590',
    'eu-west-1',
    'H */6 * * 1',
    'linux/amd64', // change to 'linux/amd64,linux/arm64' once the timeout when building images is fixed
    'nl-pros-centaurus-squad-releases',
)
