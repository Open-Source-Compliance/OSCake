/********************************************************
 * OSCake / OSCF = Open Source Compliance Description
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

package de.oscake.strict.generator

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.lang.String;
import java.util.*;  
import java.util.stream.*;  

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import de.oscake.strict.oscf.ComplianceArtifactCollection
import de.oscake.strict.oscf.ComplianceArtifactPackage
import de.oscake.strict.oscf.ComplianceArtifactSet
import de.oscake.strict.oscf.ComplianceArtifactSetMIT
import de.oscake.strict.oscf.ComplianceArtifactSetBSD2Clause
import de.oscake.strict.oscf.ComplianceArtifactSetBSD3Clause
import de.oscake.strict.oscf.ComplianceArtifactSetApache20
import de.oscake.strict.oscf.ComplianceArtifactSetEpl10
import de.oscake.strict.oscf.ComplianceArtifactSetEpl20
import de.oscake.strict.oscf.ComplianceArtifactSetLgpl20
import de.oscake.strict.oscf.ComplianceArtifactSetLgpl21

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */

class OscfGenerator extends AbstractGenerator {
  
val String notDeliverable="-> can not be included in this copy/portion of the software";
val String notInOrigRepo="neither part of the file nor part of the original repository";

/*
 * This is a hack! 
 * 
 * TODO: at the end this must be determined by an external configuration file
 */
val String absRepoPath="/home/kreincke/data.dsl";
val String muLicenseDir="multiply.usable.licenses";

val List<String> muLicenseSet = new ArrayList<String>();

override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
 val cac = resource.contents.head as ComplianceArtifactCollection;
 fsa.generateFile(cac.cacid+'.oscf.md', cac.toCode('  '));
}

/**
 *  aggregates and pipes the ComplianceArtifactCollection (evaluates the OSCF file)
 * 
 *  @param cac the ComplianceArtifactCollection 
 *  @param mtag the main indentation
 */

def CharSequence toCode(ComplianceArtifactCollection cac, String mtab) '''
# Open Source Compliance File for the package «cac.cacid» 
## 0.) About this file:

This *Open Source Compliance File* 
`«cac.cacid+'.oscf.md'»`
valid of and for the program collection 
**«cac.cacid»** 
has been compiled on the base  of the case specific data repository 
`«absRepoPath»/«cac.cacContDir»` 
containing the case specific files gathered by ORT and the OSCake 
collection of multiply usable license files 
«absRepoPath»/«muLicenseDir»

«IF  moreMeta(cac)»This OSCF ...
      
«IF ( cac.cacComposer !== null)»* was compiled by «cac.cacComposer»,«ENDIF»
«IF ( cac.cacReleaseDate !== null )»* was released at «cac.cacReleaseDate»,«ENDIF»
«IF ( cac.cacReleaseNumber !== null )»* got the release number «cac.cacReleaseNumber»)«ENDIF»
«ENDIF»

## 1.) About the delivering company:

*OSCake*-***TODO*** *organize an include of company specific data*

## 2.) Summary of the included FOSS packages (BOM)

«IF ( cac.complianceArtifactPackages !== null && cac.complianceArtifactPackages.length > 0)»
  «FOR pkg : cac.complianceArtifactPackages»
- [«pkg.capid»](#«clearId(pkg.capid)») («pkg.capReleaseNumber») «pkg.casl.head.spdxId»
  «ENDFOR»  
«ENDIF»

## 3.) Compliance artifacts for the included FOSS packages
«var int iter=0»
«var int oter=0»
«IF ( cac.complianceArtifactPackages !== null && cac.complianceArtifactPackages.length > 0)»
«FOR pkg : cac.complianceArtifactPackages»
<a name="«clearId(pkg.capid)»"></a>
### 3.«(iter+=1).toString» Package: «pkg.capid»
- Release: «pkg.capReleaseNumber»
- Repository: [«pkg.capRepoUrl»](«pkg.capRepoUrl»)
- ComplianceArtifacts:
«mtab»- Scope: DEFAULT
  «IF ((oter=0)==0)»«ENDIF»
  «FOR dcas : pkg.casl»
«mtab+mtab»- Compliance artifacts for the «(oter+=1).toString». default licensing statement 
«insertCas(dcas,mtab+mtab+mtab,cac.cacContDir)»
  «ENDFOR»
  «FOR scasl : pkg.dirComplianceArtifactSets»
«mtab»- Scope: DIR
«mtab+mtab»- Dir: «scasl.dpath»
    «IF ((oter=0)==0)»«ENDIF»
    «FOR cas : scasl.dcasl»
«mtab+mtab»- Compliance artifacts for the «(oter+=1).toString». licensing statement in dir *«scasl.dpath»*: 
«insertCas(cas, mtab+mtab+mtab,cac.cacContDir)»
    «ENDFOR»
  «ENDFOR»
  «FOR scasl : pkg.fileComplianceArtifactSets»
«mtab»- Scope: FILE    
«mtab+mtab»- File: «scasl.fpath»
    «IF ((oter=0)==0)»«ENDIF»
    «FOR cas : scasl.fcasl»
«mtab+mtab»- Compliance artifacts for the «(oter+=1).toString». licensing statement in file *«scasl.fpath»*:  
«insertCas(cas, mtab+mtab+mtab,cac.cacContDir)»
    «ENDFOR»
  «ENDFOR»
  
«ENDFOR»  
«ENDIF»

«var int lter=0»
## 4.) Multiply Usable License Texts
«Collections.sort(muLicenseSet)»
«FOR String lic : muLicenseSet»
### 4.«(lter+=1).toString» «lic» License Text:
«quoteFileContent(absRepoPath,muLicenseDir,lic.toLowerCase() +".md")»
«ENDFOR»

'''



def boolean moreMeta(ComplianceArtifactCollection cac) {
  if (cac.cacComposer !== null) return true;
  if (cac.cacReleaseDate !== null) return true;
  if (cac.cacReleaseNumber !== null) return true;
  return false;
}
 

/**
 * routes the writer to the license specific artifacts
 * 
 * @param  tabs the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required 
 *
 * @todo containerPath and type must be determined by evaluating the meta data
 */



def insertCas(ComplianceArtifactSet cas, String tabs, String cacContDir) '''
«tabs»- LicenseID: «cas.spdxId»
  
«IF (cas.spdxId == '"MIT"')»
  «insertMitCas(tabs,cas.casMit,cacContDir)»
«ELSEIF (cas.spdxId == '"BSD-2-Clause"')»
  «insertBsd2clCas(tabs,cas.casBsd2Cl,cacContDir)»
«ELSEIF (cas.spdxId == '"BSD-3-Clause"')»
  «insertBsd3clCas(tabs,cas.casBsd3Cl,cacContDir)»
«ELSEIF (cas.spdxId == '"Apache-2.0"')»
  «insertApache20Cas(tabs,cas.casApache20,cacContDir)»
«ELSEIF (cas.spdxId == '"EPL-1.0"')»
  «insertEpl10Cas(tabs,cas.casEpl10,cacContDir)»
«ELSEIF (cas.spdxId == '"EPL-2.0"')»
   «insertEpl20Cas(tabs,cas.casEpl20,cacContDir)»
 «ELSEIF ( (cas.spdxId == '"LGPL-2.0-or-later"')
        || (cas.spdxId == '"LGPL-2.0"'))»
   «insertLgpl20Cas(tabs,cas.casLgpl20,cacContDir
   )» 
«ELSEIF ( (cas.spdxId == '"LGPL-2.1-or-later"')
         || (cas.spdxId == '"LGPL-1.0"'))»
   «insertLgpl21Cas(tabs,cas.casLgpl21,cacContDir)»
«ELSEIF (cas.spdxId == '"noassertion"')»
  «insertNoAssertCas(tabs)»
«ELSE»«insertUnknownCas(tabs)»
«ENDIF»
'''

/* -----------------------------------------------------------------
 * No follow the methods which insert the license specific artifacts
 * in accordance with the definitions in the DSL following the
 * pattern 'ComplianceArtifactSet$LICENSE'.
 * ---------------------------------------------------------------- */

/**
 * inserts the artifacts required my the MIT license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the MIT
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertMitCas(
    String lmtab,
    ComplianceArtifactSetMIT cas,
    String cacContDir
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»
«ELSEIF  ((cas.lfPath == '911')||(cas.lfPath == '"911"')) »
ORT has reported an issue concerning this file.
Please curate that issue on ORT level.

THIS OSCF MUST NOT BE DISTRIBUTED IN THIS FORM!
«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(absRepoPath,cacContDir,cas.lfPath)»
«ENDIF»
«toMuLicenseSet("MIT",cas.ltype)»
'''

/**
 * inserts the artifacts required my the BSD-2-Clause license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the BSD-2-Clause
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertBsd2clCas(
    String lmtab,
    ComplianceArtifactSetBSD2Clause cas,
    String cacContDir
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»
«ELSEIF  ((cas.lfPath == '911')||(cas.lfPath == '"911"')) »
ORT has reported an issue concerning this file.
Please curate that issue on ORT level.

THIS OSCF MUST NOT BE DISTRIBUTED IN THIS FORM!

«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(absRepoPath,cacContDir,cas.lfPath)»
«ENDIF»
«toMuLicenseSet("BSD-2-Clause",cas.ltype)»
'''  


/**
 * inserts the artifacts required my the BSD-3-Clause license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the BSD-3-Clause license
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertBsd3clCas(
    String lmtab,
    ComplianceArtifactSetBSD3Clause cas,
    String cacContDir
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»
«ELSEIF  ((cas.lfPath == '911')||(cas.lfPath == '"911"')) »
ORT has reported an issue concerning this file.
Please curate that issue on ORT level.

THIS OSCF MUST NOT BE DISTRIBUTED IN THIS FORM!

«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(absRepoPath,cacContDir,cas.lfPath)»
«ENDIF»
«toMuLicenseSet("BSD-3-Clause",cas.ltype)»
''' 

/**
 * inserts the artifacts required my the Apache-2.0 license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the Apache-2.0 license
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */

def String insertApache20Cas(
    String lmtab,
    ComplianceArtifactSetApache20 cas,
    String cacContDir
  ) '''
«lmtab»- LicenseText: see [Apache20](Apache20)

«IF (cas.nfPath == 'null')»
  «lmtab»- NoticeFile: «lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»

«ELSEIF  ((cas.nfPath == '911')||(cas.nfPath == '"911"')) »
ORT has reported an issue concerning this file.
Please curate that issue on ORT level.

THIS OSCF MUST NOT BE DISTRIBUTED IN THIS FORM!

«ELSE»
«lmtab»- NoticeFile: 
«quoteFileContent(absRepoPath,cacContDir,cas.nfPath)»
«ENDIF»
«toMuLicenseSet("Apache-2.0",cas.ltype)»
''' 


/**
 * inserts the artifacts required my the Eclipse Public License 1.0
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the Apache-2.0 license
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */

def String insertEpl10Cas(
    String lmtab,
    ComplianceArtifactSetEpl10 cas,
    String cacContDir
  ) '''
«lmtab»- LicenseText: see [EPL-1.0](EPL-1.0)
«toMuLicenseSet("EPL-1.0",cas.ltype)»
''' 

/**
 * inserts the artifacts required my the Eclipse Public License 2.0
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the Apache-2.0 license
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */

def String insertEpl20Cas(
    String lmtab,
    ComplianceArtifactSetEpl20 cas,
    String cacContDir
  ) '''
«lmtab»- LicenseText: see [EPL-2.0](EPL-2.0)
''' 
/**
 * inserts the artifacts required my the Lgpl 2.x
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the Apache-2.0 license
 * @param cacContDir the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */

def String insertLgpl20Cas(
    String lmtab,
    ComplianceArtifactSetLgpl20 cas,
    String cacContDir
  ) '''
«lmtab»- LicenseText: see [LGPL-2.0](LGPL-2.0)
''' 

def String insertLgpl21Cas(
    String lmtab,
    ComplianceArtifactSetLgpl21 cas,
    String cacContDir
  ) '''
«lmtab»- LicenseText: see [LGPL-2.1](LGPL-2.1)
''' 


/**
 * reacts on an unclear license assertion
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 */
def String insertNoAssertCas(
    String lmtab
  ) '''
«lmtab»- ERROR. OSCF must not be delivered in this form. 'No-Assertion' of the scanning tool must be clarified manually!

'''

/**
 * reacts on an unkown license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 */
def String insertUnknownCas(
    String lmtab
  ) '''
«lmtab»- LicenseText: unknown License => compliance artifacts can not be compiled!
'''

/**
 * erases unwanted signs of a string
 * 
 * @todo erase blanks 
 */
def String clearId(String istr) {
  return istr.toUpperCase();

}
/**
 * inserts the content of file as markdown quotation.
 * 
 * @param filePath the path of the file in the file or zip repository
 * @param repoPath the path of the repository
 * @param repoType = '"zip"' | '"dir"'
 * 
 * @todo implement getting the file and inserting its content
 */
def String quoteFileContent(String absRepoPath, String repoDir,String fileName) '''

```
«quoteFileInArchive(absRepoPath,repoDir,fileName)»
```

'''

def void toMuLicenseSet(String lname, String ltype) {
  
  if (ltype=='"multiply-usable"') {
    if (!(muLicenseSet.contains(lname)))
      muLicenseSet.add(lname);
  }
}

def String quoteFileInArchive(String absRepoPath, String repoDir,String fileName) {
  val String absFilePath=absRepoPath+"/"+repoDir+"/"+fileName;

  var File file = new File(absFilePath);
  if (!file.canRead() || !file.isFile()) 
    return ("ERROR: Didn't find '" + absFilePath + "'");
  
  var FileReader fr = null;
  var int c;
  
  var StringBuffer buff = new StringBuffer();
  
  try {
    fr = new FileReader(file);
    while ((c =fr.read()) != -1) {
      buff.append( c as char);
    }
    fr.close();
  } catch (IOException e) {
    return ("ERROR: Couldn't read content of file '" + absFilePath + "'");
  }
  return buff.toString();

}

}
