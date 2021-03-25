SHELL=/bin/zsh
site_root_path:=$(shell siteinfo -s 'Script factory' local_root)
manualfolder:=${site_root_path}/software/FinderHelpers/PowerRenamer/manual

.PHONY: install clean

default: trash clean install

trash:
	trash ${HOME}/Applications/PowerRenamer.app

install: trash clean
	xcodebuild -workspace PowerRenamer.xcworkspace -scheme PowerRenamer install DSTROOT=${HOME}

clean:
	xcodebuild -workspace PowerRenamer.xcworkspace -scheme PowerRenamer clean

helpbook:
	 pull-helpbook.pl --localized --source "${manualfolder}" --helpbookbundle PowerRenamerHelp --appinfoplist PowerRenamer-info.plist
