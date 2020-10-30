node {
  withEnv(['AWS_BUCKET=jobs.amazeeio.services', 'AWS_DEFAULT_REGION=us-east-2']) {
    withCredentials([
      usernamePassword(credentialsId: 'aws-s3-lagoon', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
      string(credentialsId: 'SKIP_IMAGE_PUBLISH', variable: 'SKIP_IMAGE_PUBLISH')
    ]) {
      try {
        env.CI_BUILD_TAG = env.BUILD_TAG.replaceAll('%2f','').replaceAll("[^A-Za-z0-9]+", "").toLowerCase()
        env.SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2f','-').replaceAll("[^A-Za-z0-9]+", "-").toLowerCase()
        env.SYNC_MAKE_OUTPUT = 'target'
        // make/tests will synchronise (buffer) output by default to avoid interspersed
        // lines from multiple jobs run in parallel. However this means that output for
        // each make target is not written until the command completes.
        //
        // See `man -P 'less +/-O' make` for more information about this option.
        //
        // Uncomment the line below to disable output synchronisation.
        env.SYNC_MAKE_OUTPUT = 'none'

        stage ('env') {
          sh "env"
        }

        deleteDir()

        stage ('Checkout') {
          def checkout = checkout scm
          env.GIT_COMMIT = checkout["GIT_COMMIT"]
        }

        // in order to have the newest images from upstream (with all the security updates) we clean our local docker cache on tag deployments
        // we don't do this all the time to still profit from image layer caching
        // but we want this on tag deployments in order to ensure that we publish images always with the newest possible images.
        if (env.TAG_NAME) {
          stage ('clean docker image cache') {
            sh script: "docker image prune -af", label: "Pruning images"
          }
        }

        stage ('build images') {
          sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build", label: "Building images"
        }

        stage ('push branch images to testlagoon/*') {
          withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
            try {
              if (env.SKIP_IMAGE_PUBLISH != 'true') {
                sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
                sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-baseimages BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built images to testlagoon"
              } else {
                sh script: 'echo "skipped because of SKIP_IMAGE_PUBLISH env variable"', label: "Skipping image publishing"
              }
            } catch (e) {
              echo "Something went wrong, trying to cleanup"
              cleanup()
              throw e
            }
          }
        }

        stage ('show built images') {
          sh 'docker image ls | sort -u'
        }

        if (env.TAG_NAME && env.SKIP_IMAGE_PUBLISH != 'true') {
          stage ('publish-amazeeio') {
            withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-uselagoon-baseimages", label: "Publishing built images to uselagoon"
              sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-amazeeio-baseimages", label: "Publishing legacy images to amazeeio"
            }
          }
        }

        if (env.BRANCH_NAME == 'main' && env.SKIP_IMAGE_PUBLISH != 'true') {
          stage ('save images to s3') {
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 s3-save", label: "Saving images to AWS S3"
          }
          stage ('push latest images to testlagoon') {
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-baseimages BRANCH_NAME=latest", label: "Publishing :latest images to testlagoon"
          }
        }

      } catch (e) {
        currentBuild.result = 'FAILURE'
        throw e
      } finally {
        notifySlack(currentBuild.result)
      }
    }
  }

}

def cleanup() {
  try {
    sh "make clean"
  } catch (error) {
    echo "cleanup failed, ignoring this."
  }
}

def notifySlack(String buildStatus = 'STARTED') {
    // Build status of null means success.
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'STARTED') {
        color = '#68A1D1'
    } else if (buildStatus == 'SUCCESS') {
        color = '#BDFFC3'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFE89'
    } else {
        color = '#FF9FA1'
    }

    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

    slackSend(color: color, message: msg)
}
