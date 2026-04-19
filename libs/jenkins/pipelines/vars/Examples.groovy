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

// Container Image
// Module(Number, Number, String, String)
// Module(ProjectGitLabId, PipelineTimeout, CronSchedule, SlackChannel)
// Module(3319, 'H 4 * * 1-5', 15, 'nl-pros-centaurus-squad-releases')
// Note The CRON schedule is Jenkins enabled timer. Meaning we can do random times within an hour bound. https://www.jenkins.io/doc/book/pipeline/syntax/
ContainerImage(
    84424,
    30,
    'H */8 30 * 1-5',
    'nl-pros-centaurus-squad-releases'
)
