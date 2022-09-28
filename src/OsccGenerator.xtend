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
import de.oscake.weak.oscc.FileComplianceArtifactSet

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class OsccGenerator extends AbstractGenerator {

override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
 val cac = resource.contents.head as ComplianceArtifactCollection;
 fsa.generateFile(cac.cacid+'.oscf', cac.toCode());
}
/**
 *  aggregates and pipes the ComplianceArtifactCollection (evaluates the OSCF file)
 * 
 *  @param cac the ComplianceArtifactCollection 
 *  @param mtag the main indentation
 */
def CharSequence toCode(ComplianceArtifactCollection cac) '''
{ 
  "complianceArtifactCollection" : {
    "cid" : "«cac.cacid»" ,
    «IF (isDefined(cac.cacComposer))»"author" : "«cac.cacComposer»" ,«ENDIF»
    «IF (isDefined(cac.cacReleaseNumber))»"release" : "«cac.cacReleaseNumber»" ,«ENDIF»
    «IF (isDefined(cac.cacReleaseDate))»"date" : "«cac.cacReleaseDate»" ,«ENDIF»
    "contentDir" : "« eraseZipExtension(cac.cacContPath)»" 
  } ,
  "complianceArtifactPackages" : [
    «FOR pkg : cac.complianceArtifactPackages BEFORE '' SEPARATOR ',' AFTER ''»
    {
      "pid" : "«pkg.capid»" , 
      «createKeyValuePairOfOptionalOsccElement("release", pkg.capReleaseNumber ,"," ,"MUST")»
      «createKeyValuePairOfOptionalOsccElement("repository", pkg.capRepoUrl , "," ,"SHOULD")»
      "defaultLicensings" : [
        «IF (pkg.casl !== null && pkg.casl.length > 0) »
        «FOR dcas : pkg.casl BEFORE '' SEPARATOR ',' AFTER ''»
        {
          «insertCas(dcas)»
        }
        «ENDFOR»
        «ENDIF»
      ],
      "dirLicensings" : [
        «IF (pkg.dirComplianceArtifactSets !== null && pkg.dirComplianceArtifactSets.length > 0) »
        «FOR dcasp : pkg.dirComplianceArtifactSets BEFORE '' SEPARATOR ',' AFTER ''»
        {
          "dirScope" : "«dcasp.dpath»" ,
          "dirLicenses" : [
            «FOR dcasl : dcasp.dcasl BEFORE '' SEPARATOR ',' AFTER ''»
            {
              «insertCas(dcasl)»
            }
          «ENDFOR»
          ]
        }
        «ENDFOR»
        «ENDIF»
      ],
      "fileLicensings" : [
        «IF (pkg.fileComplianceArtifactSets !== null && pkg.fileComplianceArtifactSets.length > 0) »
        «var boolean ofirst=true»
        «FOR fcasp : pkg.fileComplianceArtifactSets BEFORE '' SEPARATOR '' AFTER ''» 
        «IF isAnyLicenseReferenceRelevant(fcasp,pkg)»    
          «IF (!(ofirst))»,«ELSE»«IF (ofirst=false)»«ENDIF»«ENDIF»
          { 
            "fileScope" : "«clearScopeString(fcasp.fpath)»" ,
            «IF (fcasp.fcPath!==null && isNoticeFile(fcasp.fpath))»
            "fileContentInArchive" : "«fcasp.fcPath»" ,
            «ENDIF»
            "fileLicenses" : [
              «var boolean ifirst=true»
              «FOR fcas : fcasp.fcasl BEFORE '' SEPARATOR '' AFTER ''»
              «IF isThisFileLicenseReferenceRelevant(fcas,pkg) »
              «IF (!(ifirst))»,«ELSE»«IF (ifirst=false)»«ENDIF»«ENDIF»
              { 
                «insertCas(fcas)»
              }
              «ENDIF»
             «ENDFOR»
            ]
          }
        «ENDIF»
        «ENDFOR»
        «ENDIF»
      ]     
    }
    «ENDFOR»            
  ] 
}
'''

def boolean isNoticeFile(String scope) {
  if (scope === null) return false;
  if (scope == '"NOTICE"') return true;
  if (scope == '"NOTICE.txt"') return true;
  if (scope == '"NOTICE.md"') return true;
  return false;
}

def String clearScopeString(String scope) {
  if (scope === null) return "911";
  if (scope == '"NOTICE"') return "NOTICE";
  if (scope == '"NOTICE.txt"') return "NOTICE.txt";
  if (scope == '"NOTICE.md"') return "NOTICE.md";
  return scope;
}

/*
 * A licensing statement (in any focus) only must be fulfilled
 * if it has been found
 */
def boolean isAnyLicenseReferenceRelevant (FileComplianceArtifactSet fcasl,ComplianceArtifactPackage pkg) {
  for ( ComplianceArtifactSet fcas :  fcasl.fcasl) {
    if (isThisFileLicenseReferenceRelevant (fcas, pkg)) return true;
  }
  return false;
}

/*
 * An entry of the file licensing statements is relevant 
 * a) if the license identifier is neither null nor 'null' and
 * b) if it is not covered by the any of the default licensing statements
 */
def boolean isThisFileLicenseReferenceRelevant (ComplianceArtifactSet fcas, ComplianceArtifactPackage pkg) {
  
  if ( fcas.spdxId === null ) return false; 
  if ( fcas.spdxId == 'null' )  return false; 

  if (isThisLicenseReferenceCoveredByAnyDefaultLicense(fcas, pkg)) return false;
  
  return true;
}



 /* 
 * A local compliance set is covered by any of the default compliance sets
 * a) if the license identifier is the same and
 * b) if local compliance set does not have its own license text (in archive)
 */
def boolean isThisLicenseReferenceCoveredByAnyDefaultLicense(ComplianceArtifactSet cas, ComplianceArtifactPackage pkg) {
  if (pkg.casl === null || pkg.casl.length == 0) return false;
  for (dcas : pkg.casl ) {
    if (dcas.spdxId.equals(cas.spdxId)) {
      if (( cas.lfPath === null ) || ( cas.lfPath.equals('null') )) return true;
      if ( cas.lfPath.equals('null') ) return true;
    }
  }
  return false;
}


def String insertCas(ComplianceArtifactSet cas) {
  if (cas.spdxId == '"MIT"') return insertMitCas(cas);
  if (cas.spdxId == '"BSD-2-Clause"') return insertBsd2clCas(cas);
  if (cas.spdxId == '"BSD-3-Clause"') return insertBsd3clCas(cas);
  if (cas.spdxId == '"Apache-2.0"') return insertApache20Cas(cas); 
  if (cas.spdxId == '"EPL-1.0"') return insertEpl10Cas(cas); 
  if (cas.spdxId == '"EPL-2.0"') return insertEpl10Cas(cas); 
  if (cas.spdxId == '"LGPL-2.0-or-later"') return insertLgpl20Cas(cas); 
  if (cas.spdxId == '"LGPL-2.1-or-later"') return insertLgpl21Cas(cas); 
  
  if ((cas.spdxId == '"noassertion"')||(cas.spdxId == '"NOASSERTION"')) return insertNoAssertCas();  
  /* this method should never been used due to  isAnyLicenseReferenceValid  */ 
  /* if (cas.spdxId == 'null') return insertNullCas(); */
  return insertUnknownCas(cas);
}

def String insertMitCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "instantiated" ,
«writeRequiredValue("licenseTextInArchive",cas.lfPath)»
'''

def String insertBsd2clCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "instantiated" ,
«writeRequiredValue("licenseTextInArchive",cas.lfPath)»
'''

def String insertBsd3clCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "instantiated" ,
«writeRequiredValue("licenseTextInArchive",cas.lfPath)»
'''




/* TODO
 * Der OsccGenerator muss checken, ob überhaupt eine Datei
 * namens NOTICE, NOTICE.txt, NOTICE.md im übermittelten
 * Dateibestand das Packages existiert.
 * 
 * Vereinfachende Annahme für den Beginn:
 * Das ApacheNoticeFile liegt im TopDirectory
 * 
 * Ob so ein File existiert kann der Generator daran testen
 * ob der Wert fcPath in einem FileComplianceArtifactSet gesetzt ist.
 * 
 * Gibt es eine solche Datei, muss der generator
 * den Wert von fcPath hier als Wert von "apacheNoticeTextInArchive" 
 * schreiben.
 * 
 * Achtung: der OSCF-Generator muss anders operieren:
 * Er überpfügt die Dateien nicht, sondern verlässt sich auf diesen Wert.
 */
def String insertApache20Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "multiply-usable" ,
«writeRequiredValue("apacheNoticeTextInArchive","NOTICE.dummy")»
'''

def String insertEpl10Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "multiply-usable"
'''

def String insertEpl20Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "multiply-usable"
'''

def String insertLgpl20Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "multiply-usable"
'''
def String insertLgpl21Cas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseType" : "multiply-usable"
'''

/*
def String insertNullCas() '''
"license" : null ,
"licenseTextInArchive" : null
'''
*/

def String insertNoAssertCas() '''
"license" : "noassertion" ,
"licenseTextInArchive" : null /* TODO MUST: write an OSCC-Task: resolve noassertion */
'''

def String insertUnknownCas(ComplianceArtifactSet cas) '''
"license" : «cas.spdxId» ,
"licenseTextInArchive" : "911"  /* TODO MUST: write an OSCC-Task: resolve 911 */
'''

def writeRequiredValue(String kword, String kval) '''
«IF (kval === null)»
"«kword»" : "911"
«ELSEIF (kval=='"911"')»
"«kword»" : "911"
«ELSEIF (kval == 'null')»
"«kword»" : null
«ELSE»
"«kword»" : "«kval»" 
«ENDIF»
'''

def String createKeyValuePairOfOptionalOsccElement(String key, String value, String cm, String state ) {
  val String comment=' /* TODO write an OSCC task: value for '+ key + ' ' + state + ' be inserted */';
  
  if (value===null) return ('"' + key + '" : "unknown" ' + cm + comment);
  if (value=="") return ('"' + key + '" : "unknown" ' + cm + comment);
  if (value=='null') return ('"' + key + '" : "unknown" ' + cm + comment);
  return ('"' + key + '" : "' + value + '" ' + cm);
}

def Boolean isDefined(String istr) {
  if ( istr === null) return false;
  if ( istr == "" ) return false;
  return true;
}

def String eraseZipExtension(String zipName) {
   if ( zipName === null) return "";
   if (zipName.endsWith(".zip"))
     return zipName.replaceAll("\\.zip*$", "");
   return zipName
}
}



