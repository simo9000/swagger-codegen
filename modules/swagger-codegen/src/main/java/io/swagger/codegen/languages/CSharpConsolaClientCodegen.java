package io.swagger.codegen.languages;

import io.swagger.codegen.SupportingFile;

import java.io.File;
import java.util.ArrayList;

public class CSharpConsolaClientCodegen extends CSharpClientCodegen {

    private ArrayList childTemplates;

    public CSharpConsolaClientCodegen() {
      embeddedTemplateDir = templateDir = "csharp";
      childTemplates = new ArrayList();
      childTemplates.add("packageSupplement.mustache");
      childTemplates.add("apiSupplement.mustache");
      childTemplates.add("clientSupplement.mustache");
      childTemplates.add("modelSupplement.mustache");
      childTemplates.add("referenceSupplement.mustache");
    }

    @Override
    public String getFullTemplateFile(String templateFile) {
      if (childTemplates.contains(templateFile))
        return "csharpConsola" + File.separator + templateFile;
      else
        return super.getFullTemplateFile(templateFile);
    }

    @Override
    public String getName() {
        return "csharpConsola";
    }

    @Override
    public void processOpts() {
        super.processOpts();
        String packageFolder = sourceFolder + File.separator + packageName;
        String clientPackageDir = packageFolder + File.separator + clientPackage;
        supportingFiles.add(new SupportingFile("apiSupplement.mustache",
                clientPackageDir, "apiSupplement.cs"));
        supportingFiles.add(new SupportingFile("clientSupplement.mustache",
                clientPackageDir, "clientSupplement.cs"));
        supportingFiles.add(new SupportingFile("modelSupplement.mustache",
                clientPackageDir, "modelSupplement.cs"));
    }
}
