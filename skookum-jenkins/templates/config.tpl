{{- define "override_config_map" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "jenkins.fullname" . }}
data:
  config.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <hudson>
      <disabledAdministrativeMonitors/>
      <version>{{ .Values.Master.ImageTag }}</version>
      <numExecutors>0</numExecutors>
      <mode>NORMAL</mode>
      <useSecurity>{{ .Values.Master.UseSecurity }}</useSecurity>
{{- if .Values.Master.GithubAuth.Enabled }}
      <authorizationStrategy class="org.jenkinsci.plugins.GithubAuthorizationStrategy" plugin="github-oauth@0.29">
        <rootACL>
          <organizationNameList class="linked-list">
            {{- range .Values.Master.GithubAuth.Organizations }}
            <string>{{ . }}</string>
            {{- end }}
          </organizationNameList>
          <adminUserNameList class="linked-list">
            {{- range .Values.Master.GithubAuth.AdminUsers }}
            <string>{{ . }}</string>
            {{- end }}
          </adminUserNameList>
          <authenticatedUserReadPermission>true</authenticatedUserReadPermission>
          <useRepositoryPermissions>true</useRepositoryPermissions>
          <authenticatedUserCreateJobPermission>true</authenticatedUserCreateJobPermission>
          <allowGithubWebHookPermission>false</allowGithubWebHookPermission>
          <allowCcTrayPermission>false</allowCcTrayPermission>
          <allowAnonymousReadPermission>false</allowAnonymousReadPermission>
          <allowAnonymousJobStatusPermission>false</allowAnonymousJobStatusPermission>
        </rootACL>
      </authorizationStrategy>
      <securityRealm class="org.jenkinsci.plugins.GithubSecurityRealm">
        <githubWebUri>https://github.com</githubWebUri>
        <githubApiUri>https://api.github.com</githubApiUri>
        <clientID>{{ .Values.Master.GithubAuth.ClientID }}</clientID>
        <clientSecret>{{ .Values.Master.GithubAuth.ClientSecret }}</clientSecret>
        <oauthScopes>read:org,user:email</oauthScopes>
      </securityRealm>
{{- else }}
      <authorizationStrategy class="hudson.security.FullControlOnceLoggedInAuthorizationStrategy">
        <denyAnonymousReadAccess>true</denyAnonymousReadAccess>
      </authorizationStrategy>
      <securityRealm class="hudson.security.LegacySecurityRealm"/>
{{- end }}
      <disableRememberMe>false</disableRememberMe>
      <projectNamingStrategy class="jenkins.model.ProjectNamingStrategy$DefaultProjectNamingStrategy"/>
      <workspaceDir>${JENKINS_HOME}/workspace/${ITEM_FULLNAME}</workspaceDir>
      <buildsDir>${ITEM_ROOTDIR}/builds</buildsDir>
      <markupFormatter class="hudson.markup.EscapedMarkupFormatter"/>
      <jdks/>
      <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
      <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
      <clouds>
        <org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud plugin="kubernetes@{{ template "jenkins.kubernetes-version" . }}">
          <name>kubernetes</name>
          <defaultsProviderTemplate>default</defaultsProviderTemplate>
          <templates>
{{- if .Values.Agent.Enabled }}
            <org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
              <inheritFrom></inheritFrom>
              <name>default</name>
              <instanceCap>2147483647</instanceCap>
              <idleMinutes>0</idleMinutes>
              <label>{{ default "default" .Values.Agent.AgentLabel }}</label>
              <nodeSelector>
                {{- $local := dict "first" true }}
                {{- range $key, $value := .Values.Agent.NodeSelector }}
                  {{- if not $local.first }},{{- end }}
                  {{- $key }}={{ $value }}
                  {{- $_ := set $local "first" false }}
                {{- end }}</nodeSelector>
                <nodeUsageMode>NORMAL</nodeUsageMode>
              <volumes>
{{- range $index, $volume := .Values.Agent.volumes }}
                <org.csanchez.jenkins.plugins.kubernetes.volumes.{{ $volume.type }}Volume>
{{- range $key, $value := $volume }}{{- if not (eq $key "type") }}
                  <{{ $key }}>{{ $value }}</{{ $key }}>
{{- end }}{{- end }}
                </org.csanchez.jenkins.plugins.kubernetes.volumes.{{ $volume.type }}Volume>
{{- end }}
              </volumes>
              <containers>
                <org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
                  <name>jnlp</name>
                  <image>{{ .Values.Agent.Image }}:{{ .Values.Agent.ImageTag }}</image>
{{- if .Values.Agent.Privileged }}
                  <privileged>true</privileged>
{{- else }}
                  <privileged>false</privileged>
{{- end }}
                  <alwaysPullImage>{{ .Values.Agent.AlwaysPullImage }}</alwaysPullImage>
                  <workingDir>/home/jenkins</workingDir>
                  <command></command>
                  <args>${computer.jnlpmac} ${computer.name}</args>
                  <ttyEnabled>false</ttyEnabled>
                  <resourceRequestCpu>{{.Values.Agent.Cpu}}</resourceRequestCpu>
                  <resourceRequestMemory>{{.Values.Agent.Memory}}</resourceRequestMemory>
                  <resourceLimitCpu>{{.Values.Agent.Cpu}}</resourceLimitCpu>
                  <resourceLimitMemory>{{.Values.Agent.Memory}}</resourceLimitMemory>
                  <envVars>
                    <org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                      <key>JENKINS_URL</key>
                      <value>http://{{ template "jenkins.fullname" . }}:{{.Values.Master.ServicePort}}{{ default "" .Values.Master.JenkinsUriPrefix }}</value>
                    </org.csanchez.jenkins.plugins.kubernetes.ContainerEnvVar>
                  </envVars>
                </org.csanchez.jenkins.plugins.kubernetes.ContainerTemplate>
              </containers>
              <envVars/>
              <annotations/>
{{- if .Values.Agent.ImagePullSecret }}
              <imagePullSecrets>
                <org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
                  <name>{{ .Values.Agent.ImagePullSecret }}</name>
                </org.csanchez.jenkins.plugins.kubernetes.PodImagePullSecret>
              </imagePullSecrets>
{{- else }}
              <imagePullSecrets/>
{{- end }}
              <nodeProperties/>
            </org.csanchez.jenkins.plugins.kubernetes.PodTemplate>
{{- end -}}
          </templates>
          <serverUrl>https://kubernetes.default.svc</serverUrl>
          <skipTlsVerify>false</skipTlsVerify>
          <namespace>{{ .Release.Namespace }}</namespace>
          <jenkinsUrl>http://{{ template "jenkins.fullname" . }}:{{.Values.Master.ServicePort}}{{ default "" .Values.Master.JenkinsUriPrefix }}</jenkinsUrl>
          <jenkinsTunnel>{{ template "jenkins.fullname" . }}-agent:50000</jenkinsTunnel>
          <containerCap>10</containerCap>
          <retentionTimeout>5</retentionTimeout>
          <connectTimeout>0</connectTimeout>
          <readTimeout>0</readTimeout>
        </org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud>
      </clouds>
      <quietPeriod>5</quietPeriod>
      <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
      <views>
        <hudson.model.AllView>
          <owner class="hudson" reference="../../.."/>
          <name>All</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
        </hudson.model.AllView>
      </views>
      <primaryView>All</primaryView>
      <slaveAgentPort>50000</slaveAgentPort>
      <label></label>
      <nodeProperties/>
      <globalNodeProperties/>
      <noUsageStatistics>true</noUsageStatistics>
    </hudson>
{{- if .Values.Master.ScriptApproval }}
  scriptapproval.xml: |-
    <?xml version='1.0' encoding='UTF-8'?>
    <scriptApproval plugin="script-security@1.27">
      <approvedScriptHashes/>
      <approvedSignatures>
{{- range $key, $val := .Values.Master.ScriptApproval }}
        <string>{{ $val }}</string>
{{- end }}
      </approvedSignatures>
      <aclApprovedSignatures/>
      <approvedClasspathEntries/>
      <pendingScripts/>
      <pendingSignatures/>
      <pendingClasspathEntries/>
    </scriptApproval>
{{- end }}
  apply_config.sh: |-
    mkdir -p /usr/share/jenkins/ref/secrets/;
    echo "false" > /usr/share/jenkins/ref/secrets/slave-to-master-security-kill-switch;
    cp -n /var/jenkins_config/config.xml /var/jenkins_home;
{{- if .Values.Master.InstallPlugins }}
    cp /var/jenkins_config/plugins.txt /var/jenkins_home;
    rm -rf /usr/share/jenkins/ref/plugins/*.lock
    /usr/local/bin/install-plugins.sh `echo $(cat /var/jenkins_home/plugins.txt)`;
{{- end }}
{{- if .Values.Master.ScriptApproval }}
    cp -n /var/jenkins_config/scriptapproval.xml /var/jenkins_home/scriptApproval.xml;
{{- end }}
{{- if .Values.Master.InitScripts }}
    mkdir -p /var/jenkins_home/init.groovy.d/;
    cp -n /var/jenkins_config/*.groovy /var/jenkins_home/init.groovy.d/
{{- end }}
{{- if .Values.Master.CredentialsXmlSecret }}
    cp -n /var/jenkins_credentials/credentials.xml /var/jenkins_home;
{{- end }}
{{- if .Values.Master.SecretsFilesSecret }}
    cp -n /var/jenkins_secrets/* /usr/share/jenkins/ref/secrets;
{{- end }}
{{- if .Values.Master.Jobs }}
    for job in $(ls /var/jenkins_jobs); do
      mkdir -p /var/jenkins_home/jobs/$job
      cp -n /var/jenkins_jobs/$job /var/jenkins_home/jobs/$job/config.xml
    done
{{- end }}
{{- range $key, $val := .Values.Master.InitScripts }}
  init{{ $key }}.groovy: |-
{{ $val | indent 4 }}
{{- end }}
  plugins.txt: |-
{{- if .Values.Master.InstallPlugins }}
{{- range $index, $val := .Values.Master.InstallPlugins }}
{{ $val | indent 4 }}
{{- end }}
{{- end }}
{{ end }}
