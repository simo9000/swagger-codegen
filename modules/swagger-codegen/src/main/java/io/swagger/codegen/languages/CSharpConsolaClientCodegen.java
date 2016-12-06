package io.swagger.codegen.languages;

import java.io.File;

public class CSharpConsolaClientCodegen extends CSharpClientCodegen {

    public CSharpConsolaClientCodegen() {
      embeddedTemplateDir = templateDir = "csharp";
    }

    @Override
    public String getFullTemplateFile(String templateFile) {
      if (templateFile.equals("packageSupplement.mustache"))
        return "csharpConsola" + File.separator + templateFile;
      else
        return super.getFullTemplateFile(templateFile);
    }

    @Override
    public String getName() {
        return "csharpConsola";
    }
}
