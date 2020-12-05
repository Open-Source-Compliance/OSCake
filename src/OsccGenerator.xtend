/********************************************************
 * OSCake / OSCC = Open Source Compliance Collection
 * Open Source Compliance artifacts knowledge engine
 * 
 * Copyright (c) {2020 Karsten Reincke, Deutsche Telekom AG
 *
 * This program is made available under the terms of the
 * Eclipse Public License 2.0 which is available at
 * http://www.eclipse.org/legal/epl-2.0
 *
 * SPDX-License-Identifier: EPL-2.0
  *******************************************************/
package de.oscake.weak.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import de.oscake.weak.oscc.ComplianceArtifactCollection
import de.oscake.weak.oscc.ComplianceArtifactPackage
import de.oscake.weak.oscc.ComplianceArtifactSet

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class OsccGenerator extends AbstractGenerator {



override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
 val cac = resource.contents.head as ComplianceArtifactCollection;
 fsa.generateFile(cac.cacid+'-gen.oscd', cac.toCode());
}
/**
 *  aggregates and pipes the ComplianceArtifactCollection (evaluates the OSCD file)
 * 
 *  @param cac the ComplianceArtifactCollection 
 *  @param mtag the main indentation
 */
def CharSequence toCode(ComplianceArtifactCollection cac) '''
{ 
  "complianceArtifactCollection" : {
    "cid" : "«cac.cacid»-gen" ,
    «IF (isDefined(cac.cacComposer))»"author" : "«cac.cacComposer»" ,«ENDIF»
    «IF (isDefined(cac.cacReleaseNumber))»"release" : "«cac.cacReleaseNumber»" ,«ENDIF»
    «IF (isDefined(cac.cacReleaseDate))»"date" : "«cac.cacReleaseDate»" ,«ENDIF»
    "containerPath" : "«cac.cacContPath»" ,
    "containerType" : «cac.cacContType»
  } ,
  "complianceArtifactPackages" : [
    «FOR pkg : cac.complianceArtifactPackages BEFORE '' SEPARATOR ' ,' AFTER ''»
    {
      "pid" : "«pkg.capid»" , 
      «IF (isDefined(pkg.capReleaseNumber))»"release" : "«pkg.capReleaseNumber»" ,«ENDIF»
      «IF (isDefined(pkg.capRepoUrl))»"repository" : "«pkg.capRepoUrl»" ,«ENDIF»
      "defaultLicensings" : [
        «IF (pkg.defComplianceArtifactSets !== null && pkg.defComplianceArtifactSets.length > 0) »
        «FOR dcas : pkg.defComplianceArtifactSets BEFORE '' SEPARATOR ' ,' AFTER ''»
        {
          "defaultScope" : «dcas.dstatus» ,
          «insertCas(dcas.cas)»
        }
        «ENDFOR»
        «ENDIF»
      ] ,
      "dirLicensings" : [
        «IF (pkg.dirComplianceArtifactSets !== null && pkg.dirComplianceArtifactSets.length > 0) »
        «FOR dcas : pkg.dirComplianceArtifactSets BEFORE '' SEPARATOR ' ,' AFTER ''»
        {
          "dirScope" : "«dcas.dpath»" ,
          «insertCas(dcas.cas)»
        }
        «ENDFOR»
        «ENDIF»
      ] ,
      "fileLicensings" : [
        «IF (pkg.fileComplianceArtifactSets !== null && pkg.fileComplianceArtifactSets.length > 0) »
        «FOR fcas : pkg.fileComplianceArtifactSets BEFORE '' SEPARATOR ' ,' AFTER ''»
        {
          "fileScope" : "«fcas.fpath»" ,
          «insertCas(fcas.cas)»
        }
        «ENDFOR»
        «ENDIF»
      ]     
    }
    «ENDFOR»
  ],
  "multiplyUsableFossLicenses" : [ ]
}
'''

def String insertCas(ComplianceArtifactSet cas) {
  if (cas.spdxId == '"MIT"') return insertMitCas(cas);
  if (cas.spdxId == '"BSD-2-Clause"') return insertBsd2clCas(cas);
  if (cas.spdxId == '"BSD-3-Clause"') return insertBsd3clCas(cas);
  if (cas.spdxId == '"Apache-2.0"') return insertApache20Cas(cas);
  return insertUnknownCas(cas);
}

def String insertMitCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
«IF (cas.status !== null && cas.status=='"unclear"')»
"licenseText" : "ERROR! Review needed"
«ELSEIF cas.lfPath=='Null'»
"licenseText" : "not part of the repository"
«ELSE»
"licenseText" : "«cas.lfPath»"
«ENDIF»
'''

def String insertBsd2clCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
«IF (cas.status !== null && cas.status=='"unclear"')»
"licenseText" : "ERROR! Review needed"
«ELSEIF cas.lfPath=='Null'»
"licenseText" : "not part of the repository"
«ELSE»
"licenseText" : "«cas.lfPath»"
«ENDIF»
'''

def String insertBsd3clCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
«IF (cas.status !== null && cas.status=='"unclear"')»
"licenseText" : "ERROR! Review needed"
«ELSEIF cas.lfPath =='Null'»
"licenseText" : "not part of the repository"
«ELSE»
"licenseText" : "«cas.lfPath»"
«ENDIF»
'''

def String insertApache20Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseText" : "multiply-usable" ,
«IF (cas.nfPath == 'Null')»
"noticeText" : "not part of the repository"
«ELSE»
"noticeText" : "«cas.nfPath»"
«ENDIF»
'''

def String insertUnknownCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseText" : "ERROR: OSCake does not know this license"
'''

def Boolean isDefined(String istr) {
  if ( istr === null) return false;
  if ( istr == "" ) return false;
  return true;
}

}



