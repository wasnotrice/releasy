require File.expand_path("helpers/helper", File.dirname(__FILE__))

folder = 'pkg/test_app_0_1_WIN32_FROM_WRAPPER'

context Relapse::Builders::Win32FolderFromWrapper do
  setup { Relapse::Builders::Win32FolderFromWrapper.new new_project }

  teardown do
    Dir.chdir $original_path
    Rake::Task.clear
  end

  hookup do
    Dir.chdir project_path
  end

  asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not set/
  if Gem.win_platform?
    denies(:valid_for_platform?)
  else
    asserts(:valid_for_platform?)
  end

  context "invalid wrapper" do
    hookup do
      topic.wrapper = "whatever"
    end

    asserts(:generate_tasks).raises Relapse::ConfigError, /wrapper not valid/
  end

  context "valid" do
    hookup do
      stub(topic).valid_for_platform?.returns(true) # Need to do this so we can test on all platforms.
      topic.wrapper = win32_folder_wrapper
      topic.icon = "test_app.ico"
      topic.gemspecs = Bundler.definition.specs_for([:development])
      topic.generate_tasks
    end

    asserts(:folder_suffix).equals "WIN32_FROM_WRAPPER"
    asserts(:wrapper).equals win32_folder_wrapper

    context "tasks" do
      tasks = [
          [ :Task, "build:win32:folder_from_wrapper", [folder] ],
          [ :FileTask, "pkg", [] ], # byproduct of using #directory
          [ :FileTask, folder, source_files + [win32_folder_wrapper]],
      ]

      test_tasks tasks
    end

    context "generate" do
      hookup { Rake::Task["build:win32:folder_from_wrapper"].invoke }

      asserts("files copied to folder") { source_files.all? {|f| File.read("#{folder}/src/#{f}") == File.read(f) } }
      asserts("readme copied to folder") { File.read("#{folder}/README.txt") == File.read("README.txt") }
      asserts("license copied to folder") { File.read("#{folder}/LICENSE.txt") == File.read("LICENSE.txt") }

      asserts("test_app.exe has been created") { File.exists?("#{folder}/test_app.exe") }
      asserts("test_app.exe is correct") { File.read("#{folder}/test_app.exe") == File.read("#{win32_folder_wrapper}/console.exe") }
      denies("console.exe left in folder") { File.exists?("#{folder}/console.exe") }
      denies("windows.exe left in folder") { File.exists?("#{folder}/windows.exe") }

      asserts("ruby.exe left in bin") { File.exists?("#{folder}/bin/ruby.exe") }
      denies("rubyw.exe left in folder") { File.exists?("#{folder}/bin/rubyw.exe") }

      asserts("plenty of dlls copied") { Dir["#{folder}/bin/*.dll"].size >= 6 }

      asserts("relapse_runner.rb is correct") { File.read("#{folder}/relapse_runner.rb").strip == File.read(data_file("relapse_runner.rb")).strip }

      %w[bundler chipmunk gosu rr riot texplay yard].each do |gem|
        asserts("#{gem} gem specification copied") { not Dir["#{folder}/gemhome/specifications/#{gem}*.gemspec"].empty? }
        asserts("#{gem} gem folder copied") { not Dir["#{folder}/gemhome/gems/#{gem}*"].empty? }
      end

      asserts("program output") { %x[#{folder}/test_app.exe] }.equals "test run!\n"
    end
  end
end