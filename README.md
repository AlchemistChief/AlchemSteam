# Workshop Item Downloader

This batch script allows you to download Steam Workshop items easily using `steamcmd`.

## How to use

1. Run the `downloadWorkshopItem.bat` script.
2. The script will prompt you to enter a Steam Workshop item URL.
3. `steamcmd` will be automatically installed the first time you run the script (if not already installed).
4. The selected Workshop item will be downloaded and saved into the `.downloadedFiles` folder, organized by the item’s title.

## Notes

- Make sure you have an active internet connection.
- Downloads are performed anonymously using `steamcmd`.
- The script uses Steam's public API to retrieve item details.

## License

This project is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.