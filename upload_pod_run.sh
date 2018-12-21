a=`grep -E 's.version.*=' VDWebView.podspec`
b=${a#*\'}
version=${b%\'*}
LineNumber=`grep -nE 's.version.*=' VDWebView.podspec | cut -d : -f1`
echo "current version is ${version}, please enter the new version:"
read newVersion
# 修改VDCommon.podspec文件中的version为指定值
sed -i "" "${LineNumber}s/${version}/${newVersion}/g" VDWebView.podspec
# 修改readme版本号
sed -i "" "s/${version}/${newVersion}/g" README.md
echo "git commit and git push origin master ？ (y/n):"
read isCommit
if [[ ${isCommit} = "y" ]] || [[ ${isCommit} = "Y" ]]; then
	git add .
	echo "please ender commit info:"
	read commitInfo
	# 先commit再pull后push
	git commit -am ${commitInfo}
	echo "push origin master..."
	git pull origin master
	git push origin master
fi
echo "add tag and push tag..."
git tag ${newVersion}
git push origin master --tags
pod trunk push VDWebView.podspec --allow-warnings