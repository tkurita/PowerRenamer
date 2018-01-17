.PHONY: install clean

default: trash clean install

trash:
	trash ${HOME}/Applications/PowerRenamer.app

install: trash clean
	xcodebuild -workspace PowerRenamer.xcworkspace -scheme PowerRenamer install DSTROOT=${HOME}

clean:
	xcodebuild -workspace PowerRenamer.xcworkspace -scheme PowerRenamer clean DSTROOT=${HOME}

