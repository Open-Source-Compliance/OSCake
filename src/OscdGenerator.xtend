/********************************************************
 * OSCake / OSCD = Open Source Compliance Description
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

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext

import de.oscake.strict.oscd.ComplianceArtifactCollection
import de.oscake.strict.oscd.ComplianceArtifactPackage
import de.oscake.strict.oscd.ComplianceArtifactSet
import de.oscake.strict.oscd.ComplianceArtifactSetMIT
import de.oscake.strict.oscd.ComplianceArtifactSetBSD2Clause
import de.oscake.strict.oscd.ComplianceArtifactSetBSD3Clause
import de.oscake.strict.oscd.ComplianceArtifactSetApache20
import de.oscake.strict.oscd.MultiplyUsableFossLicense

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */

class OscdGenerator extends AbstractGenerator {
  
val String notDeliverable="-> can not be included in this copy/portion of the software";
val String notInOrigRepo="neither part of the file nor part of the original repository";

override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
 val cac = resource.contents.head as ComplianceArtifactCollection;
 fsa.generateFile(cac.cacid+'.oscf.md', cac.toCode('  '));
}

/**
 *  aggregates and pipes the ComplianceArtifactCollection (evaluates the OSCD file)
 * 
 *  @param cac the ComplianceArtifactCollection 
 *  @param mtag the main indentation
 */

def CharSequence toCode(ComplianceArtifactCollection cac, String mtab) '''
# Open Source Compliance File for the package «cac.cacid» 
## 0.) About this file:

Based on the data container `«cac.cacContPath»` of type: «cac.cacContType», 
the Open Source Compliance Artifacts of and for the program collection 
**«cac.cacid»** have been gathered into the *Open Source Compliance File*
`«cac.cacid+'.oscf.md'»`. «IF  moreMeta(cac)»This OSCF ...
      
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
«insertCas(dcas,mtab+mtab+mtab)»
  «ENDFOR»
  «FOR scasl : pkg.dirComplianceArtifactSets»
«mtab»- Scope: DIR
«mtab+mtab»- Dir: «scasl.dpath»
    «IF ((oter=0)==0)»«ENDIF»
    «FOR cas : scasl.dcasl»
«mtab+mtab»- Compliance artifacts for the «(oter+=1).toString». licensing statement in dir *«scasl.dpath»*: 
«insertCas(cas, mtab+mtab+mtab)»
    «ENDFOR»
  «ENDFOR»
  «FOR scasl : pkg.fileComplianceArtifactSets»
«mtab»- Scope: FILE    
«mtab+mtab»- File: «scasl.fpath»
    «IF ((oter=0)==0)»«ENDIF»
    «FOR cas : scasl.fcasl»
«mtab+mtab»- Compliance artifacts for the «(oter+=1).toString». licensing statement in file *«scasl.fpath»*:  
«insertCas(cas, mtab+mtab+mtab)»
    «ENDFOR»
  «ENDFOR»
  
«ENDFOR»  
«ENDIF»

«IF ( cac.multiplyUsableFossLicenses !== null && cac.multiplyUsableFossLicenses.length > 0)»
«IF ((oter=0)==0)»«ENDIF»
## 4.) Multiply used license texts:
  «FOR lic : cac.multiplyUsableFossLicenses»
<a name=«clearId(lic.spdxId)»></a>
### 4.«(oter+=1).toString» «lic.spdxId» License Text
«quoteFileContent(lic.lfPath,"GeneralLicRepo","GeneralLicRepoType") »
  «ENDFOR»  
«ENDIF»
'''

def boolean moreMeta(ComplianceArtifactCollection cac) {
  if (cac.cacComposer !== null) return true;
  if (cac.cacReleaseDate !== null) return true;
  if (cac.cacReleaseNumber !== null) return true;
  return false;
}
 
/* 


'''
*/
/**
 * routes the writer to the license specific artifacts
 * 
 * @param  tabs the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required 
 *
 * @todo containerPath and type must be determined by evaluating the meta data
 */



def insertCas(ComplianceArtifactSet cas, String tabs) '''
«tabs»- LicenseID: «cas.spdxId»
«IF (cas.spdxId == '"MIT"')»
  «insertMitCas(tabs,cas.casMit,"contPath","contType")»
«ELSEIF (cas.spdxId == '"BSD-2-Clause"')»
  «insertBsd2clCas(tabs,cas.casBsd2Cl,"contPath","contType")»
«ELSEIF (cas.spdxId == '"BSD-3-Clause"')»
  «insertBsd3clCas(tabs,cas.casBsd3Cl,"contPath","contType")»
«ELSEIF (cas.spdxId == '"Apache-2.0"')»
  «insertApache20Cas(tabs,cas,"contPath","contType")»
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
 * @param cacContPath the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertMitCas(
    String lmtab,
    ComplianceArtifactSetMIT cas,
    String cacContPath,
    String cacContType
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»

«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(cas.lfPath,cacContPath,cacContType)»
«ENDIF»
'''

/**
 * inserts the artifacts required my the BSD-2-Clause license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the BSD-2-Clause
 * @param cacContPath the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertBsd2clCas(
    String lmtab,
    ComplianceArtifactSetBSD2Clause cas,
    String cacContPath,
    String cacContType
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»

«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(cas.lfPath,cacContPath,cacContType)»
«ENDIF»
'''  


/**
 * inserts the artifacts required my the BSD-3-Clause license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the BSD-3-Clause license
 * @param cacContPath the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */
def String insertBsd3clCas(
    String lmtab,
    ComplianceArtifactSetBSD3Clause cas,
    String cacContPath,
    String cacContType
  ) '''
«IF (cas.lfPath == 'null')»
«lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»

«ELSE»
«lmtab»- LicenseText:
«quoteFileContent(cas.lfPath,cacContPath,cacContType)»
«ENDIF»
''' 

/**
 * inserts the artifacts required my the Apache-2.0 license
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 * @param cas the set of compliance artifacts required by the Apache-2.0 license
 * @param cacContPath the path of the collection container 
 * @param cacContType the type of the collection container ("zip" | "dir")
 */

def String insertApache20Cas(
    String lmtab,
    ComplianceArtifactSet cas,
    String cacContPath,
    String cacContType
  ) '''
«lmtab»- LicenseText: see [«cas.spdxId»](«clearId(cas.spdxId)»)
«IF (cas.casApache20 == 'null')»
«lmtab»- NoticeFile: «lmtab»- LicenseText: «notInOrigRepo» «notDeliverable»

«ELSE»
«lmtab»- NoticeFile: 
«quoteFileContent(cas.casApache20.nfPath,cacContPath,cacContType)»
«ENDIF»
''' 

/**
 * reacts on an unclear license assertion
 * 
 * @param lmtab the indentation string (due to the md-quotations we must manage this manually) 
 */
def String insertNoAssertCas(
    String lmtab
  ) '''
«lmtab»- ERROR. OSDF must not be delivered in this form. 'No-Assertion' of the scanning tool must be clarified manually!

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
def String quoteFileContent(String filePath, String repoPath, String repoType) '''

```
*OSCake*-***TODO*** fetch the file **«filePath»** from repository 
*«repoPath»* (type *«repoType»*)
and insert its content as a quote at this position
```

'''

}
