return {
  'mfussenegger/nvim-jdtls',
  ft = 'java',
  config = function()
    local jdtls = require 'jdtls'

    local mason_pkg = vim.fn.stdpath 'data' .. '/mason/packages/jdtls'
    local launcher_jar = vim.fn.glob(mason_pkg .. '/plugins/org.eclipse.equinox.launcher_*.jar')
    local config_dir = mason_pkg .. '/config_linux'

    local function start_jdtls()
      -- Recompute per-buffer so each project gets its own workspace
      local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
      local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-workspace/' .. project_name

      jdtls.start_or_attach {
        cmd = {
          'java',
          '-Declipse.application=org.eclipse.jdt.ls.core.id1',
          '-Dosgi.bundles.defaultStartLevel=4',
          '-Declipse.product=org.eclipse.jdt.ls.core.product',
          '-Dlog.level=ALL',
          '-Xmx1g',
          '--add-modules=ALL-SYSTEM',
          '--add-opens', 'java.base/java.util=ALL-UNNAMED',
          '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
          '-jar', launcher_jar,
          '-configuration', config_dir,
          '-data', workspace_dir,
        },
        root_dir = jdtls.setup.find_root { '.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle' }
          or vim.fn.expand '%:p:h',
        settings = {
          java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = 'fernflower' },
          },
        },
      }
    end

    -- For java buffers opened after this plugin loads
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'java',
      callback = start_jdtls,
    })

    -- For the current buffer (FileType already fired before plugin loaded)
    start_jdtls()
  end,
}
